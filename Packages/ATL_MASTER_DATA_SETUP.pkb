--------------------------------------------------------
--  DDL for Package Body ATL_MASTER_DATA_SETUP
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOM"."ATL_MASTER_DATA_SETUP" 
AS
   l_user_id        VARCHAR2 (100);
   l_user_role_id   VARCHAR2 (100);
   l_module_name    VARCHAR2 (100);
   l_first_name     VARCHAR2 (100);
   l_last_name      VARCHAR2 (100);
   l_email          VARCHAR2 (100);
   l_plant_code     VARCHAR2 (100);
   l_password       VARCHAR2 (100);
   l_user_exist     NUMBER;

   PROCEDURE create_user (payload       VARCHAR2,
                          MESSAGE   OUT VARCHAR2,
                          success   OUT VARCHAR2)
   AS
   BEGIN
      SELECT json_value (payload, '$.userId'),
             json_value (payload, '$.userRoleId'),
             json_value (payload, '$.firstName'),
             json_value (payload, '$.lastName'),
             json_value (payload, '$.email'),
             json_value (payload, '$.plantCode'),
             json_value (payload, '$.password')
        INTO l_user_id,
             l_user_role_id,
             l_first_name,
             l_last_name,
             l_email,
             l_plant_code,
             l_password
        FROM DUAL;

      SELECT COUNT (*)
        INTO l_user_Exist
        FROM um_user
       WHERE user_id = l_user_id;

      IF l_user_exist > 0
      THEN
         MESSAGE := 'User Exist';
         success := 'N';
      ELSE
         INSERT INTO um_user (USER_ID,
                              USER_ROLE_ID,
                              STATUS,
                              PASSWORD,
                              PLANT_CODE,
                              FIRST_NAME,
                              LAST_NAME,
                              EMAIL_ID)
              VALUES (l_user_id,
                      l_user_role_id,
                      'ACTIVE',
                      l_password,
                      l_plant_code,
                      l_first_name,
                      l_last_name,
                      l_email);

         IF (SQL%FOUND)
         THEN
            success := 'Y';
            MESSAGE := 'User Created';
         ELSE
            success := 'N';
            MESSAGE := 'User Not Created ' || SQLERRM;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         success := 'N';
         MESSAGE := 'User Not Created ' || SQLCODE || '-' || SQLERRM;
   END create_user;

   PROCEDURE change_password (payload       VARCHAR2,
                              MESSAGE   OUT VARCHAR2,
                              success   OUT VARCHAR2)
   AS
      l_user_id      VARCHAR2 (100);
      l_password     VARCHAR2 (100);
      l_user_exist   NUMBER;
   BEGIN
      SELECT json_value (payload, '$.userId'),
             json_value (payload, '$.password')
        INTO l_user_id, l_password
        FROM DUAL;


      SELECT COUNT (*)
        INTO l_user_Exist
        FROM um_user
       WHERE user_id = l_user_id;

      IF l_user_exist = 0
      THEN
         MESSAGE := 'User does not Exist';
         success := 'N';
      ELSE
         UPDATE um_user
            SET password = l_password
          WHERE user_id = l_user_id;

         IF (SQL%FOUND)
         THEN
            success := 'Y';
            MESSAGE := 'Password Updated';
         ELSE
            success := 'N';
            MESSAGE := 'Password Not Updated : ' || SQLERRM;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         success := 'N';
         MESSAGE := 'Password Not Updated : ' || SQLCODE || '-' || SQLERRM;
   END change_password;
END atl_master_data_setup;

/
