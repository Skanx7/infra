import pandas as pd
import requests
import shutil
import os
import csv
import logging

# --- CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.abspath(os.path.join(BASE_DIR, "..", "init"))
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "03-world.sql")
TEMP_DIR = os.path.join(BASE_DIR, "temp_geonames")

URL_COUNTRIES = "http://download.geonames.org/export/dump/countryInfo.txt"
URL_STATES = "http://download.geonames.org/export/dump/admin1CodesASCII.txt"
URL_CITIES = "http://download.geonames.org/export/dump/cities15000.zip"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)


class RawSql:
    def __init__(self, value: str) -> None:
        self.value = value

def download_file(url, dest_path):
    if os.path.exists(dest_path):
        logger.info(f"File exists, skipping download: {dest_path}")
        return
    
    logger.info(f"Downloading {url}...")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)

def escape_sql(val):
    """Helper to escape single quotes for SQL."""
    if pd.isna(val): return ""
    return str(val).replace("'", "''")

def write_batch_inserts(file_obj, table_name, columns, data_rows, batch_size=1000):
    """Writes efficient multi-row INSERT statements."""
    if not data_rows:
        return

    logger.info(f"Writing {len(data_rows)} rows to {table_name}...")
    
    for i in range(0, len(data_rows), batch_size):
        chunk = data_rows[i:i + batch_size]
        values_list = []
        
        for row in chunk:
            formatted_vals = []
            for v in row:
                if isinstance(v, RawSql):
                    formatted_vals.append(v.value)
                elif v is None:
                    formatted_vals.append("NULL")
                elif isinstance(v, str):
                    formatted_vals.append(f"'{v}'")
                else:
                    formatted_vals.append(str(v))
            values_list.append(f"({', '.join(formatted_vals)})")
        
        cols_str = ", ".join(columns)
        vals_str = ",\n".join(values_list)
        file_obj.write(f"INSERT INTO {table_name} ({cols_str}) VALUES\n{vals_str}\nON CONFLICT DO NOTHING;\n\n")

def to_float(val):
    if val in (None, ""):
        return None
    try:
        return float(val)
    except ValueError:
        return None


def to_int(val):
    if val in (None, ""):
        return None
    try:
        return int(val)
    except ValueError:
        return None


def generate_sql():
    # 1. Setup Directories
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(TEMP_DIR, exist_ok=True)

    # 2. Download Data
    country_file = os.path.join(TEMP_DIR, "countryInfo.txt")
    state_file = os.path.join(TEMP_DIR, "admin1CodesASCII.txt")
    cities_zip = os.path.join(TEMP_DIR, "cities15000.zip")

    download_file(URL_COUNTRIES, country_file)
    download_file(URL_STATES, state_file)
    download_file(URL_CITIES, cities_zip)

    # 3. Unpack Cities
    logger.info("Unpacking cities...")
    shutil.unpack_archive(cities_zip, TEMP_DIR)
    cities_txt = os.path.join(TEMP_DIR, "cities15000.txt")

    # 4. Start Writing SQL File
    logger.info(f"Generating SQL file at {OUTPUT_FILE}...")
    
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        
        # --- SECTION 1: DDL (Schema & Tables) ---
        f.write("-- =============================================\n")
        f.write("-- 1. SCHEMA DEFINITION\n")
        f.write("-- =============================================\n")
        f.write("CREATE SCHEMA IF NOT EXISTS world;\n\n")

        # Table: Countries
        f.write("CREATE TABLE IF NOT EXISTS world.countries (\n")
        f.write("    iso2 CHAR(2) PRIMARY KEY,\n")
        f.write("    name TEXT NOT NULL,\n")
        f.write("    continent TEXT,\n")
        f.write("    currency CHAR(3)\n")
        f.write(");\n\n")

        # Table: Subdivisions
        f.write("CREATE TABLE IF NOT EXISTS world.subdivisions (\n")
        f.write("    id UUID PRIMARY KEY DEFAULT uuidv7(),\n")
        f.write("    country_iso2 CHAR(2) REFERENCES world.countries(iso2),\n")
        f.write("    code TEXT,\n")
        f.write("    name TEXT\n")
        f.write(");\n")
        f.write("CREATE INDEX IF NOT EXISTS idx_subdiv_country ON world.subdivisions(country_iso2, code);\n\n")

        # Table: Cities
        f.write("CREATE TABLE IF NOT EXISTS world.cities (\n")
        f.write("    id UUID PRIMARY KEY DEFAULT uuidv7(),\n")
        f.write("    name TEXT NOT NULL,\n")
        f.write("    country_iso2 CHAR(2) REFERENCES world.countries(iso2),\n")
        f.write("    subdivision_name TEXT,\n")
        f.write("    latitude NUMERIC,\n")
        f.write("    longitude NUMERIC,\n")
        f.write("    geom geometry(Point, 4326),\n")
        f.write("    timezone TEXT,\n")
        f.write("    population INT\n")
        f.write(");\n")
        f.write("CREATE INDEX IF NOT EXISTS idx_cities_geo ON world.cities USING GIST(geom);\n\n")

        # --- SECTION 2: DATA INGESTION ---
        f.write("-- =============================================\n")
        f.write("-- 2. DATA INSERTS\n")
        f.write("-- =============================================\n")

        # Process Countries
        cols_country = ['iso_alpha2', 'iso_alpha3', 'iso_numeric', 'fips_code', 'country_name', 'capital', 'area_sqkm', 'population', 'continent', 'tld', 'currency_code', 'currency_name', 'phone', 'postal_code_format', 'postal_code_regex', 'languages', 'geonameid', 'neighbours', 'equivalent_fips_code']
        df_countries = pd.read_csv(country_file, sep='\t', comment='#', names=cols_country, keep_default_na=False)
        
        country_rows = []
        for _, row in df_countries.iterrows():
            country_rows.append([
                row['iso_alpha2'], 
                escape_sql(row['country_name']), 
                row['continent'], 
                row['currency_code']
            ])
        write_batch_inserts(f, "world.countries", ["iso2", "name", "continent", "currency"], country_rows)

        # Process States
        df_states = pd.read_csv(state_file, sep='\t', names=['code', 'name', 'name_ascii', 'geonameid'], keep_default_na=False)
        split_data = df_states['code'].str.split('.', n=1, expand=True)
        df_states['country_code'] = split_data[0]
        df_states['admin1_code'] = split_data[1]

        state_rows = []
        state_map = {} 
        
        for _, row in df_states.iterrows():
            name_clean = escape_sql(row['name_ascii'])
            state_rows.append([
                row['country_code'],
                row['admin1_code'],
                name_clean
            ])
            state_map[row['code']] = name_clean

        write_batch_inserts(f, "world.subdivisions", ["country_iso2", "code", "name"], state_rows)

        # Process Cities
        cols_city = ['geonameid', 'name', 'asciiname', 'alternatenames', 'latitude', 'longitude', 'feature_class', 'feature_code', 'country_code', 'cc2', 'admin1_code', 'admin2_code', 'admin3_code', 'admin4_code', 'population', 'elevation', 'dem', 'timezone', 'modification_date']
        df_cities = pd.read_csv(cities_txt, sep='\t', names=cols_city, keep_default_na=False, quoting=csv.QUOTE_NONE)

        city_rows = []
        for _, row in df_cities.iterrows():
            full_code = f"{row['country_code']}.{row['admin1_code']}"
            state_name = state_map.get(full_code, '')
            state_name_esc = state_name.replace("'", "''")
            
            lat = to_float(row['latitude'])
            lon = to_float(row['longitude'])
            geom_expr = None
            if lat is not None and lon is not None:
                geom_expr = RawSql(f"ST_SetSRID(ST_Point({lon}, {lat}), 4326)")

            city_rows.append([
                escape_sql(row['asciiname']),
                row['country_code'],
                state_name_esc,
                lat,
                lon,
                geom_expr,
                row['timezone'],
                to_int(row['population'])
            ])

        write_batch_inserts(
            f,
            "world.cities",
            [
                "name",
                "country_iso2",
                "subdivision_name",
                "latitude",
                "longitude",
                "geom",
                "timezone",
                "population",
            ],
            city_rows,
        )

    # Cleanup
    try:
        shutil.rmtree(TEMP_DIR)
        logger.info("Temporary files cleaned up.")
    except Exception as e:
        logger.warning(f"Could not remove temp dir: {e}")

    logger.info("Done! 'init/02-world.sql' is ready.")

if __name__ == "__main__":
    generate_sql()