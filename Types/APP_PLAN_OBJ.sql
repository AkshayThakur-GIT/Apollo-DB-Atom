--------------------------------------------------------
--  DDL for Type APP_PLAN_OBJ
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "ATOM"."APP_PLAN_OBJ" 
AS
  object
  (
    appstatusenum          VARCHAR2(100),
    approvedquantity       NUMBER,
    availablequantity      NUMBER,
    batchcode              VARCHAR2(10),
    category               VARCHAR2(10),
    comments               VARCHAR2(100),
    deletedapprquantity    NUMBER,
    destinationdescription VARCHAR2(100),
    destinationlocation    VARCHAR2(20),
    tempdispatchdate       DATE,
    dispatchedquantity     NUMBER,
    id                     NUMBER,
    tempinsertdate         DATE,
    insertuser             VARCHAR2(20),
    itemdescription        VARCHAR2(200),
    itemid                 VARCHAR2(20),
    linenumber             NUMBER,
    marketsegment          VARCHAR2(10),
    planid                 NUMBER,
    priority               NUMBER,
    quantity               NUMBER,
    reservedquantity       NUMBER,
    sourcelocation         VARCHAR2(20),
    status                 VARCHAR2(50),
    totalavailablequantity NUMBER,
    tte                    NUMBER,
    unapprovedquantity     NUMBER,
    deletedunapprquantity  NUMBER,
    tempupdatedate         DATE,
    updateuser             VARCHAR2(20),
    weight                 NUMBER,
    weightuom              VARCHAR2(5),
    volume                 NUMBER,
    volumeuom              VARCHAR2(5),
    loaded                 NUMBER);

/
