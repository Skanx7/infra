INSERT INTO companies.sector_classifications (name, organization, level_names, description) VALUES 
('GICS', 'MSCI & S&P', ARRAY['Sector', 'Industry Group', 'Industry', 'Sub-Industry'], 'Global Industry Classification Standard, used by MSCI and S&P'),
('ICB', 'FTSE Russell', ARRAY['Industry', 'Supersector', 'Sector', 'Subsector'], 'Industry Classification Benchmark, used by FTSE Russell'),
('BICS', 'Bloomberg', ARRAY['Sector', 'Industry Group', 'Industry', 'Sub-Industry'], 'Bloomberg Industry Classification System'),
('TRBC', 'Refinitiv (LSEG)', ARRAY['Economic Sector', 'Business Sector', 'Industry Group', 'Industry', 'Activity'], 'Thomson Reuters Business Classification, comprehensive 5-level system'),
('NAICS', 'US/Canada/Mexico Gov', ARRAY['Sector', 'Subsector', 'Industry Group', 'Industry', 'National Industry'], 'North American Industry Classification System, the standard for federal statistical agencies'),
('SIC', 'US Government (SEC)', ARRAY['Division', 'Major Group', 'Industry Group', 'Industry'], 'Standard Industrial Classification, deprecated but still used by the SEC (EDGAR)'),
('NACE', 'European Union', ARRAY['Section', 'Division', 'Group', 'Class'], 'Nomenclature of Economic Activities, the European standard (derived from ISIC)'),
('ISIC', 'United Nations', ARRAY['Section', 'Division', 'Group', 'Class'], 'International Standard Industrial Classification of All Economic Activities');