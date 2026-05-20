with page_views_by_content AS (
  SELECT
    pv.app_id,
    pv.content_id,
    pv.experience_id,
   COUNT(DISTINCT pv.page_view_id) AS page_view_count
  FROM PF_PROD_DB.public.page_views_unified pv
  WHERE pv.app_id = '3e164e28-57a9-43bd-9441-e67405263760'
  AND pv.start_time_utc >= DATEADD(year, -2, CURRENT_DATE())
  AND DATE(pv.start_time_utc) <= CURRENT_DATE()  
  
 GROUP BY app_id, content_id, experience_id
)
select 
  ct.id AS content_id,
  ct.content_uuid,
  ct.organization_id,
  og.name AS organization_name,
  e.id AS experience_id,
  e.name AS experience_name,
  e.experience_type,
  e.unique_id AS experience_unique_id,
  ct.internal_title,
  ct.title,
  ct.slug AS content_slug,
  COALESCE(NULLIF(TRIM(ec.custom_slug), ''), ct.slug) AS effective_content_slug,
  ou.url AS experience_url_path,
CASE
  WHEN ou.id IS NOT NULL THEN
    CONCAT(
      'https://',
      COALESCE(NULLIF(TRIM(og.sharing_domain_url), ''),NULLIF(TRIM(og.custom_domain), ''),CONCAT(og.subdomain, '.pathfactory.com')),'/',ou.url,'/c/',
      COALESCE(NULLIF(TRIM(ec.custom_slug), ''), ct.slug) )
  ELSE
    CONCAT(
      'https://',
      COALESCE(NULLIF(TRIM(og.sharing_domain_url), ''),NULLIF(TRIM(og.custom_domain), ''),CONCAT(og.subdomain, '.pathfactory.com')),'/c/',
      COALESCE(NULLIF(TRIM(ec.custom_slug), ''), ct.slug),'?x=',e.unique_id)
  END AS expected_track_url,


  ct.updated_at AS content_updated_at,
  e.updated_at AS experience_updated_at,
COUNT(DISTINCT e.id) OVER (PARTITION BY ct.id) AS count_track,
CASE WHEN COUNT(DISTINCT e.id) OVER (PARTITION BY ct.id) > 0 THEN 'Yes' ELSE 'No' END AS active_in_track,
  
  CASE
  WHEN e.experience_type = 0 THEN 'Recommend'
  WHEN e.experience_type = 1 THEN 'Target'
  WHEN e.experience_type = 2 THEN 'Website'
  WHEN e.experience_type = 3 THEN 'Virtual Event'
  WHEN e.experience_type = 4 THEN 'Microsite'
  WHEN e.experience_type = 5 AND te.experience_type = 'templated_experience' THEN 'Templated Experience'   
  WHEN e.experience_type = 5 AND te.experience_type = 'content_playlist' THEN 'Content Playlist'  
  WHEN e.experience_type = 6 THEN 'Chatfactory'
  WHEN e.experience_type IS NULL THEN 'Website Tools'
END AS experience_type_label,
CASE WHEN COALESCE(ct.engagement_threshold, 0) > 0 THEN 'Yes' ELSE 'No' END AS engagement_yn,
COALESCE(pvc.page_view_count, 0) AS page_view_count,
og.sharing_domain_url,
og.custom_domain,
og.subdomain,
ec.custom_slug,
ct.slug,
e.unique_id,
OU.ID


FROM PF_PROD_DB.PUBLIC.CT_CONTENTS ct
INNER JOIN PF_PROD_DB.PUBLIC.ORGANIZATIONS og ON og.id = ct.organization_id
LEFT JOIN PF_PROD_DB.PUBLIC.EXPERIENCE_CONTENTS ec ON ec.content_id = ct.id
LEFT JOIN PF_PROD_DB.PUBLIC.EXPERIENCES e ON e.id = ec.experience_id
LEFT JOIN PF_PROD_DB.PUBLIC.ORGANIZATION_URLS ou ON ou.experience_id = e.id AND ou.organization_id = e.organization_id
LEFT JOIN PF_PROD_DB.PUBLIC.TEMPLATED_EXPERIENCES te ON te.experience_id = ec.experience_id  
LEFT JOIN page_views_by_content pvc ON pvc.content_id = ct.id AND pvc.experience_id = e.id AND pvc.app_id = og.uuid

WHERE 
e.name !='#all' 
--e.deleted IS DISTINCT FROM TRUE 
AND COALESCE(ct.deleted, FALSE) = FALSE  
and ct.content_group= 'content_library' 
and (ct.is_valid_asset= true or ct.is_valid_asset is null)
AND og.uuid = '3e164e28-57a9-43bd-9441-e67405263760’;   