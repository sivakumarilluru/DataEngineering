-- ========================================================
-- Stored Procedure: SP_CampaignContentDetails
-- Purpose: Get content and experience details with page view metrics
-- Author: Data Engineering
-- Created: 2026-06-08
-- ========================================================

CREATE OR REPLACE PROCEDURE SP_CampaignContentDetails(
    p_org_uuid VARCHAR,
    p_lookback_years INT DEFAULT 2
)
RETURNS TABLE (
    content_id NUMBER,
    content_uuid VARCHAR,
    organization_id NUMBER,
    organization_name VARCHAR,
    experience_id NUMBER,
    experience_name VARCHAR,
    experience_type NUMBER,
    experience_unique_id VARCHAR,
    internal_title VARCHAR,
    title VARCHAR,
    content_slug VARCHAR,
    effective_content_slug VARCHAR,
    experience_url_path VARCHAR,
    expected_track_url VARCHAR,
    content_updated_at TIMESTAMP_NTZ,
    experience_updated_at TIMESTAMP_NTZ,
    count_track NUMBER,
    active_in_track VARCHAR,
    experience_type_label VARCHAR,
    engagement_yn VARCHAR,
    page_view_count NUMBER,
    sharing_domain_url VARCHAR,
    custom_domain VARCHAR,
    subdomain VARCHAR,
    custom_slug VARCHAR,
    slug VARCHAR,
    unique_id VARCHAR,
    organization_url_id NUMBER
)
LANGUAGE SQL
AS
$$
BEGIN
  RETURN TABLE (
    WITH page_views_by_content AS (
      SELECT
        pv.app_id,
        pv.content_id,
        pv.experience_id,
        COUNT(DISTINCT pv.page_view_id) AS page_view_count
      FROM PF_PROD_DB.public.page_views_unified pv
      WHERE pv.app_id = p_org_uuid
      AND pv.start_time_utc >= DATEADD(year, -p_lookback_years, CURRENT_DATE())
      AND DATE(pv.start_time_utc) <= CURRENT_DATE()  
      GROUP BY app_id, content_id, experience_id
    )
    SELECT 
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
      ou.id AS organization_url_id
    FROM PF_PROD_DB.PUBLIC.CT_CONTENTS ct
    INNER JOIN PF_PROD_DB.PUBLIC.ORGANIZATIONS og ON og.id = ct.organization_id
    LEFT JOIN PF_PROD_DB.PUBLIC.EXPERIENCE_CONTENTS ec ON ec.content_id = ct.id
    LEFT JOIN PF_PROD_DB.PUBLIC.EXPERIENCES e ON e.id = ec.experience_id
    LEFT JOIN PF_PROD_DB.PUBLIC.ORGANIZATION_URLS ou ON ou.experience_id = e.id AND ou.organization_id = e.organization_id
    LEFT JOIN PF_PROD_DB.PUBLIC.TEMPLATED_EXPERIENCES te ON te.experience_id = ec.experience_id  
    LEFT JOIN page_views_by_content pvc ON pvc.content_id = ct.id AND pvc.experience_id = e.id AND pvc.app_id = og.uuid
    WHERE 
      e.name != '#all' 
      AND COALESCE(ct.deleted, FALSE) = FALSE  
      AND ct.content_group = 'content_library' 
      AND (ct.is_valid_asset = true OR ct.is_valid_asset IS NULL)
      AND og.uuid = p_org_uuid
  );
END;
$$;


-- ========================================================
-- USAGE EXAMPLES
-- ========================================================

-- Example 1: Call with organization UUID and default 2-year lookback
CALL SP_CampaignContentDetails('3e164e28-57a9-43bd-9441-e67405263760');

-- Example 2: Call with custom lookback period (1 year)
CALL SP_CampaignContentDetails('3e164e28-57a9-43bd-9441-e67405263760', 1);

-- Example 3: Store results in a table
CREATE OR REPLACE TABLE campaign_content_details AS
CALL SP_CampaignContentDetails('3e164e28-57a9-43bd-9441-e67405263760', 2);
