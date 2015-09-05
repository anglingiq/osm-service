
DROP FUNCTION find_nearest_lakes(lat double precision, lon double precision, inset numeric);

DROP FUNCTION find_nearest_waterways(lat double precision, lon double precision, inset numeric);
CREATE OR REPLACE FUNCTION find_nearest_waterways(lat double precision, lon double precision, inset numeric default 0.1) 
RETURNS TABLE (
	id bigint,
	the_name text,
	latitude double precision,
	longitude double precision,
	-- centerLat double precision,
	-- centerLon double precision,
  distance numeric) AS $$ 
BEGIN

RETURN QUERY
SELECT DISTINCT
		osm_id AS id,
		name AS the_name,
    ST_Y((dp).geom) AS latitude,
    ST_X((dp).geom) AS longitude,
    -- ST_Y(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLat,
    -- ST_X(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLon,
    round((ST_Distance_Sphere(ST_ClosestPoint(way, ST_Centroid(way)), ST_SetSRID(ST_MakePoint(lon, lat), 4326)) / 1000*1.0)::numeric, 2) AS distance
FROM
  (SELECT way,
          ST_DumpPoints(way) AS dp,
          name,
          osm_id
   FROM planet_osm_line
   WHERE (way && ST_MakeEnvelope(lon - inset, lat - inset, lon + inset, lat + inset, 4326)) AND waterway='river') AS blert
   ORDER BY (dp).path;
 END;
 $$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION find_nearest_lakes(lat double precision, lon double precision, inset numeric default 0.1) 
RETURNS TABLE (
	id bigint,
	the_name text,
	latitude double precision,
	longitude double precision,
	-- centerLat double precision,
	-- centerLon double precision,
  distance numeric) AS $$ 
BEGIN

RETURN QUERY
SELECT
		osm_id as id,
		name as the_name,
       	ST_Y((dp).geom) AS latitude,
       	ST_X((dp).geom) AS longitude,
       	-- ST_Y(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLat,
       	-- ST_X(ST_ClosestPoint(way, ST_Centroid(way))) AS centerLon,
        round((ST_Distance_Sphere(ST_ClosestPoint(way, ST_Centroid(way)), ST_SetSRID(ST_MakePoint(lon, lat), 4326)) / 1000*1.0)::numeric, 2) AS distance
FROM
  (SELECT way,
  		  ST_DumpPoints(way) AS dp,
          name,
          osm_id
   FROM planet_osm_polygon
   WHERE (way && ST_MakeEnvelope(lon - inset, lat - inset, lon + inset, lat + inset, 4326)) AND "natural"='water' AND name IS NOT NULL) AS blertz
   ORDER BY distance ASC;
 END;
 $$ LANGUAGE plpgsql;

