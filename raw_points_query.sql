CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct` AS

    -- Extract the blockgroup geometry with its population
    WITH blockgroup_data AS (
        SELECT dem.total_pop AS population, geog.geom AS geom
        FROM `carto-do-public-data.usa_acs.demographics_sociodemographics_usa_blockgroup_2015_5yrs_20142018` dem
        INNER JOIN `carto-do-public-data.carto.geography_usa_blockgroup_2015` geog
        ON dem.geoid = geog.geoid
    ),

    point_data AS (

        -- Vaccinated people section
        SELECT bqcarto.random.ST_GENERATEPOINTS(blockgroup_data.geom, CAST(blockgroup_data.population * counties_vacc.Series_Complete_Pop_Pct * 0.01 AS INT64)) points, 'true' AS vaccinated 
        FROM `bigquery-public-data.geo_us_boundaries.counties` counties
        INNER JOIN `cartobq.maps.cdc_raw_counties_data` counties_vacc ON counties_vacc.FIPS = counties.county_fips_code
        INNER JOIN blockgroup_data 
        ON ST_CONTAINS(counties.county_geom, ST_CENTROID(blockgroup_data.geom))

        UNION ALL

        -- Non vaccinated people section
        SELECT bqcarto.random.ST_GENERATEPOINTS(blockgroup_data.geom, CAST(blockgroup_data.population * (1.0 - counties_vacc.Series_Complete_Pop_Pct * 0.01) AS INT64)) points, 'false' AS vaccinated 
        FROM `bigquery-public-data.geo_us_boundaries.counties` counties
        INNER JOIN `cartobq.maps.cdc_raw_counties_data` counties_vacc ON counties_vacc.FIPS = counties.county_fips_code
        INNER JOIN blockgroup_data 
        ON ST_CONTAINS(counties.county_geom, ST_CENTROID(blockgroup_data.geom))

        UNION ALL

        -- There are many counties with unknown data
        SELECT bqcarto.random.ST_GENERATEPOINTS(blockgroup_data.geom, CAST(blockgroup_data.population AS INT64)) points, 'unknown' AS vaccinated 
        FROM `bigquery-public-data.geo_us_boundaries.counties` counties
        INNER JOIN `cartobq.maps.cdc_raw_counties_data` counties_vacc ON counties_vacc.FIPS = counties.county_fips_code
        INNER JOIN blockgroup_data 
        ON ST_CONTAINS(counties.county_geom, ST_CENTROID(blockgroup_data.geom)) AND counties_vacc.Series_Complete_Pop_Pct IS NULL
    
    )

    SELECT unnested_points AS geom, vaccinated, ROW_NUMBER() OVER() AS point_order
    FROM point_data, UNNEST(point_data.points) as unnested_points;

    -- Downsample the table to 10% of the data
    CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_blockgroups_10pct` AS
    SELECT *
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct`
    WHERE RAND() < 0.1;

    -- Downsample the table to 1% of the data
    CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_blockgroups_1pct` AS
    SELECT *
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct`
    WHERE RAND() < 0.01;
