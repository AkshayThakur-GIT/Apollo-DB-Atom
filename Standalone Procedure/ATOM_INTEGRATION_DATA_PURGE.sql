--------------------------------------------------------
--  DDL for Procedure ATOM_INTEGRATION_DATA_PURGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOM"."ATOM_INTEGRATION_DATA_PURGE" (P_AGEING_DAYS NUMBER) AUTHID CURRENT_USER
AS

/* 
  Purpose:        Used for purging integration data from ATOM application 
  Remarks:       
  Who             Date            Description
  ------          ----------      ----------------------------------------------
  Akshay Thakur   23-JUL-2020     Created 

*/

  C_LIMIT CONSTANT PLS_INTEGER DEFAULT 5000;
  CURSOR INT_CUR
  IS
    SELECT
      A.ROWID AS A_ROWID,
      B.ROWID AS B_ROWID
    FROM
      INTEGRATION_LOG A,
      INTEGRATION_ERRORS B
    WHERE
      A.ERROR_LOG_ID         = B.ERROR_REC_ID(+)
    AND A.INSERT_DATE < SYSDATE - P_AGEING_DAYS;
TYPE INT_AAT
IS
  TABLE OF INT_CUR%ROWTYPE INDEX BY PLS_INTEGER;
  L_INTEGRATION_LOG INT_AAT;
  L_COUNT     PLS_INTEGER := 1;
  L_INT_LOG_COUNT PLS_INTEGER :=0;
  L_INT_ERR_COUNT PLS_INTEGER :=0;
  L_TOT_REC_COUNT PLS_INTEGER;
  L_START_TIME NUMBER;
  L_END_TIME NUMBER;
  L_TOT_TIME NUMBER;
  L_SQL VARCHAR2(400);
  L_BODY      CLOB;
  L_BODY_HTML CLOB;
  L_EMAIL_IDS VARCHAR2(4000):= 'akshay.thakur@inspirage.com,akshay.thakur1388@gmail.com';
BEGIN
  L_START_TIME:=DBMS_UTILITY.GET_TIME;
  /* Disable FK constraint because it is slowing down overall execution */
  L_SQL := 'ALTER TABLE INTEGRATION_LOG DISABLE CONSTRAINT INTEGRATION_LOG_FK1';
    EXECUTE IMMEDIATE L_SQL;
  OPEN INT_CUR;
  LOOP
    FETCH
      INT_CUR BULK COLLECT
    INTO
      L_INTEGRATION_LOG LIMIT C_LIMIT;
    --DBMS_OUTPUT.put_line ('Retrieved in RUN '|| L_COUNT ||' = ' ||L_INTEGRATION_LOG.COUNT);    
    IF L_INTEGRATION_LOG.COUNT <> 0 THEN
    FORALL INDX IN 1 .. L_INTEGRATION_LOG.COUNT
    DELETE
    FROM
      INTEGRATION_LOG
    WHERE
      ROWID = L_INTEGRATION_LOG(INDX).A_ROWID;
    L_INT_LOG_COUNT :=   L_INT_LOG_COUNT+SQL%ROWCOUNT;
    --DBMS_OUTPUT.put_line ('Total rows deleted from INTEGRATION_LOG = ' ||
    --SQL%ROWCOUNT);
    FORALL INDX IN 1 .. L_INTEGRATION_LOG.COUNT
    DELETE
    FROM
      INTEGRATION_ERRORS
    WHERE
      ROWID=L_INTEGRATION_LOG(INDX).B_ROWID
      AND L_INTEGRATION_LOG(INDX).B_ROWID IS NOT NULL;
    --DBMS_OUTPUT.put_line ('Total rows deleted from INTEGRATION_ERRORS = ' ||
    --SQL%ROWCOUNT);
    L_INT_ERR_COUNT :=   L_INT_ERR_COUNT+SQL%ROWCOUNT;
    L_COUNT := L_COUNT + 1;
    ELSE
      
      L_INT_LOG_COUNT := L_INT_LOG_COUNT;
      L_INT_ERR_COUNT := L_INT_ERR_COUNT;
      
    END IF;
    COMMIT;
    EXIT
    WHEN L_INTEGRATION_LOG.COUNT=0;
  END LOOP;
  CLOSE INT_CUR;
  /* Enable FK constraint once execution is done */
  L_SQL := 'ALTER TABLE INTEGRATION_LOG ENABLE CONSTRAINT INTEGRATION_LOG_FK1';
    EXECUTE IMMEDIATE L_SQL;
  L_END_TIME:=DBMS_UTILITY.GET_TIME;
  L_TOT_TIME := TO_NUMBER(TO_CHAR((L_END_TIME - L_START_TIME)/100,'000000.00'));
  L_TOT_REC_COUNT := L_INT_LOG_COUNT+L_INT_ERR_COUNT;
  --DBMS_OUTPUT.PUT_LINE('Execution Completed : ' || TO_CHAR((END_TIME - START_TIME)/100) || ' Seconds');
  --DBMS_OUTPUT.PUT_LINE('Integration Log Table Records : '||L_INT_LOG_COUNT);
  --DBMS_OUTPUT.PUT_LINE('Integration Error Table Records : '||L_INT_ERR_COUNT);
  
  /* Send Email for output */
  L_BODY := 'To view the content of this message, please use an HTML enabled mail client.'||UTL_TCP.CRLF;
  L_BODY_HTML := '<html><body>';
  L_BODY_HTML := L_BODY_HTML ||'Integration Data Purge completed in : '||L_TOT_TIME|| ' Seconds<BR/><BR/>';
  L_BODY_HTML := L_BODY_HTML || '<B>Below is the summary :</B><BR/>';
  L_BODY_HTML := L_BODY_HTML || 'Total Records : '||L_TOT_REC_COUNT||'<BR/>';
  L_BODY_HTML := L_BODY_HTML || 'Integration Log Table Records : '||L_INT_LOG_COUNT||'<BR/>';
  L_BODY_HTML := L_BODY_HTML || 'Integration Error Table Records : '||L_INT_ERR_COUNT||'<BR/>';
  L_BODY_HTML := L_BODY_HTML ||'</body></html>'; 
  --DBMS_OUTPUT.PUT_LINE('Email Body :'||L_BODY_HTML);
  ATL_UTIL_PKG.SEND_EMAIL(L_EMAIL_IDS,
                          'XX',
                          L_BODY,
                          L_BODY_HTML,
                          'Data Purge Notification!!');
  
  
END;

/
