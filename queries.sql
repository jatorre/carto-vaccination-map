CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_quadgrid18_100pct` AS

-- To avoid group of false/true records, a randomness based on the actual percetange of vaccination is applied
SELECT unnested_points geom, IF( RAND() < pct * 0.01, true, false ) AS vaccinated, ROW_NUMBER() OVER() AS point_order FROM(

    -- Extract the quadkey geometry with its population
    WITH quadint_data AS (
    SELECT quadkey_spatial_feature.geoid quadint, bqcarto.quadkey.ST_BOUNDARY(bqcarto.quadkey.QUADINT_FROMQUADKEY(quadkey_spatial_feature.geoid)) geom, quadkey_spatial_feature.population population
    FROM `carto-do.carto.derived_spatialfeatures_usa_quadgrid18_v1_yearly_2020` quadkey_spatial_feature
    )

    -- For each quadkey at the required level generate as many points as population
    SELECT bqcarto.random.ST_GENERATEPOINTS(quadint_data.geom, CAST(quadint_data.population AS INT64)) points, counties_vacc.Series_Complete_Pop_Pct pct 
    FROM `bigquery-public-data.geo_us_boundaries.counties` counties
    INNER JOIN `cartobq.maps.cdc_raw_counties_data` counties_vacc ON counties_vacc.FIPS = counties.county_fips_code
    INNER JOIN quadint_data 
    ON ST_CONTAINS(counties.county_geom, ST_CENTROID(quadint_data.geom))
    --AND counties.state_fips_code = '36' -- New yorK
),
UNNEST(points) AS unnested_points;

-- Downsample the table to 10% of the data
CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_quadgrid18_10pct` AS
SELECT *
FROM `cartobq.maps.covid19_vaccinated_usa_quadgrid18_100pct`
WHERE RAND() < 0.1;

-- Downsample the table to 1% of the data
CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_quadgrid18_1pct` AS
SELECT *
FROM `cartobq.maps.covid19_vaccinated_usa_quadgrid18_100pct`
WHERE RAND() < 0.01;


-- Create the tileset in a temporary table
DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_usa_tileset_temp`;

CALL bqcarto.tiler.CREATE_SIMPLE_TILESET(
R'''(
    SELECT
    CAST(vaccinated AS STRING) as vac,
    geom, 
    point_order,
    0 as zoom_min,
    6 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_quadgrid18_1pct`

    UNION ALL
    
    SELECT
    CAST(vaccinated AS STRING) as vac,
    geom, 
    point_order,
    7 as zoom_min,
    13 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_quadgrid18_10pct`

    UNION ALL

    SELECT
    CAST(vaccinated AS STRING) as vac,
    geom, 
    point_order,
    14 as zoom_min,
    16 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_quadgrid18_100pct`
    
) _a''',
R'''`cartobq.maps.covid19_vaccinated_usa_tileset_temp`''',
'''
    {
      "zoom_min": 0,
      "zoom_max": 16,
      "zoom_min_column": "zoom_min",
      "zoom_max_column": "zoom_max",
      "max_tile_size_kb":512,
      "max_tile_size_strategy":"drop_fraction_as_needed",
      "tile_feature_order": "point_order desc",
      "properties":{
          "vac": "String",
          "point_order":"Number"
       }
    }
'''
); 

