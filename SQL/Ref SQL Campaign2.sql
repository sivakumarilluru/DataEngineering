SELECT
      E.NAME AS EXPERIENCE_NAME,
      E.UUID as EXP_UUID,
      CASE  WHEN e.experience_type = 0 THEN 'Recommend'  
            WHEN e.experience_type = 1 THEN 'Target'
            WHEN e.experience_type = 5 and TE.EXPERIENCE_TYPE='templated_experience' THEN 'Templated Experience'
            WHEN e.experience_type = 5 and TE.EXPERIENCE_TYPE='content_playlist' THEN 'Content Playlist'
            WHEN e.experience_type = 3 THEN 'VEX'
            WHEN e.experience_type = 4 THEN 'Microsites'
            WHEN e.experience_type = 6 THEN 'ChatFactory'
            WHEN e.experience_type = 9 THEN 'Website Tools' end AS EXPERIENCE_TYPE,
      date(E.created_at) as exp_created_at,date(e.updated_at) as exp_updated_date,
      COALESCE(FOL.FOLDER_NAME,'Root') AS FOLDER_NAME

      -- COALESCE(date(E.created_at),DATE(WD.CREATED_AT)) as exp_created_at


FROM PF_DEV_DB.PUBLIC.ORGANIZATIONS AS OG 
INNER JOIN PF_DEV_DB.PUBLIC.EXPERIENCES E ON E.ORGANIZATION_ID = OG.ID 
LEFT JOIN PF_DEV_DB.PUBLIC.TEMPLATED_EXPERIENCES TE ON TE.experience_id=e.id
LEFT JOIN PF_DEV_DB.PUBLIC.FOLDERS AS FOL ON E.FOLDER_ID=FOL.ID AND E.ORGANIZATION_ID=FOL.ORGANIZATION_ID
WHERE og.uuid='{{#raw system::CurrentUserAttributeText::app_id}}'
AND e.EXPERIENCE_TYPE != 2 
                   

AND CASE WHEN {{wt_exclusion}} = TRUE THEN pg.unified_experience_type != 9 else 1=1 END 

(union all

SELECT
      wd.url AS EXPERIENCE_NAME,
      wd.UUID as EXP_UUID,
     'Website Tools'  AS EXPERIENCE_TYPE,
     DATE(WD.CREATED_AT) as exp_created_at,
      DATE(WD.UPDATED_AT) as exp_updated_date,
      'Root' as FOLDER_NAME


FROM PF_DEV_DB.PUBLIC.ORGANIZATIONS AS OG 
INNER JOIN PF_DEV_DB.PUBLIC.WEBSITE_DOMAINS WD ON WD.ORGANIZATION_ID = OG.ID

WHERE og.uuid='{{#raw system::CurrentUserAttributeText::app_id}}') only CASE WHEN {{wt_exclusion}} =  False  then use this union all statement 
if true ifnore this operation (union all below table ignore)