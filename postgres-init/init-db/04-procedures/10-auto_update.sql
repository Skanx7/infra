CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE set_auto_update(tablename regclass)
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('CREATE OR REPLACE TRIGGER set_timestamp
                    BEFORE UPDATE ON %s
                    FOR EACH ROW
                    EXECUTE FUNCTION trigger_set_timestamp()',
                    tablename);
END;
$$;
