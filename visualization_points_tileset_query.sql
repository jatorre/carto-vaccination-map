-- Create the display tileset in a temporary table to avoid read/write collisions
DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_usa_tileset_temp`;
-- vaccinated property domain: ['true', 'false', 'unknown']
CALL bqcarto.tiler.CREATE_SIMPLE_TILESET(
R'''(
    SELECT
    vaccinated,
    geom, 
    point_order,
    0 as zoom_min,
    6 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_1pct`
    
    UNION ALL

    SELECT
    vaccinated,
    geom, 
    point_order,
    7 as zoom_min,
    13 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_10pct`
    
    UNION ALL
    
    SELECT
    vaccinated,
    geom, 
    point_order,
    14 as zoom_min,
    15 as zoom_max  
    FROM `cartobq.maps.covid19_vaccinated_usa_blockgroups_100pct`
    
) _a''',
R'''`cartobq.maps.covid19_vaccinated_usa_tileset_temp`''',
'''
    {
    "zoom_min": 0,
    "zoom_max": 15,
    "zoom_min_column": "zoom_min",
    "zoom_max_column": "zoom_max",
    "max_tile_size_kb":512,
    "max_tile_size_strategy":"drop_fraction_as_needed",
    "tile_feature_order": "point_order desc",
    "skip_validation" : true,
    "properties":{
        "vaccinated": "String",
        "point_order":"Number"
    }
    }
'''
);

-- Allocate the tileset in its final table
DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_usa_tileset`;
CREATE OR REPLACE TABLE `cartobq.maps.covid19_vaccinated_usa_tileset` AS 
SELECT * FROM `cartobq.maps.covid19_vaccinated_usa_tileset_temp`;
DROP TABLE IF EXISTS `cartobq.maps.covid19_vaccinated_usa_tileset_temp`;
