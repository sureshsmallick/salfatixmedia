IMPORT FGL fgldbutl
IMPORT FGL core_cst
SCHEMA salfatixmedia

#+ Connect to a database
#+
#+ This function connects to a database
#+
#+ @param pstr_dbname The database name
#+ @returnType INTEGER, STRING
#+ @return 0 -> no error occured, <> 0 otherwise
#+
FUNCTION connect(pstr_dbname)
  DEFINE
    pstr_dbname STRING,
    lint_ret INTEGER,
    lstr_msg STRING

  TRY
    CONNECT TO pstr_dbname
    --setting the mode of accessing rows.
    --possible choices: repeatable read, committed read, dirty read
    SET ISOLATION TO repeatable read
    --time to wait when rows are locked
    SET LOCK MODE TO wait 10
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Run a simple SQL Select
#+
#+ @param qry SQL SELECT query
#+ @param val Dynamic Array of String (values)
#+
Function sqlQuery( qry String, val Dynamic Array Of String )
  Define
    sqlHdl base.SqlHandle,
    i      Smallint

  Call val.clear()
  If qry Is Null Then
  Else
    Let sqlHdl = base.SqlHandle.create()
    Call sqlHdl.prepare(qry)
    Call sqlHdl.open()
    While True
      Call sqlHdl.fetch()
      If sqlca.sqlcode == NotFound Then
        Exit While
      End If
      For i=1 To sqlHdl.getResultCount()
        Let val[i] = sqlHdl.getResultValue(i)
      End For
      Exit While
    End While
  End If
End Function

Function getListForCompleter(qry String, buf String, labelList Dynamic Array Of String,keyList Dynamic Array Of Integer)
  Define
    sqlHdl base.SqlHandle,
    i   Integer

  Call labelList.clear()
  Call keyList.clear()
  Let sqlHdl = base.SqlHandle.create()
  Call sqlHdl.prepare(qry)

  If buf.getLength() > C_COMPLETER_MIN Then
    Call sqlHdl.open()
    Let i = 0
    While True
      Call sqlHdl.fetch()
      If sqlca.sqlcode == NotFound Then
        Exit While
      End If
      Let i = i + 1
      Let keyList[i] = sqlHdl.getResultValue(1)
      Let labelList[i] = sqlHdl.getResultValue(2)
      If i = C_COMPLETER_MAX Then
        Exit While
      End If
    End While
    Call sqlHdl.close()
    Let sqlHdl = Null
  End If
End Function

#+ Select all rows in the "countries" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like countries.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION country_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE countries.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE countries.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT countries.* FROM countries"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_country_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_country_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_country_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "countries" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE countries.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE countries.*
FUNCTION country_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE countries.cntr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE countries.*

  TRY
    IF p_lock THEN
      SELECT countries.*
        INTO lrec_data.*
      FROM countries
      WHERE countries.cntr_id = p_key
      FOR UPDATE
    ELSE
      SELECT countries.*
        INTO lrec_data.*
      FROM countries
      WHERE countries.cntr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a phone prefix from the "countries" table
#+
#+ @param p_key country primary key
#+
#+ @returnType STRING
#+ @return     country phone prefix
FUNCTION country_get_phoneprefix(p_key)
  DEFINE
    p_key LIKE countries.cntr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    l_data LIKE countries.cntr_phonecode

  INITIALIZE l_data TO NULL
  TRY
    SELECT countries.cntr_phonecode
      INTO l_data
    FROM countries
    WHERE countries.cntr_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN l_data
END FUNCTION
    
#+ Select all rows in the "states" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like states.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION state_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE states.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE states.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT states.* FROM states"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_state_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_state_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_state_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "states" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE states.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE states.*
FUNCTION state_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE states.stt_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE states.*

  TRY
    IF p_lock THEN
      SELECT states.*
        INTO lrec_data.*
      FROM states
      WHERE states.stt_id = p_key
      FOR UPDATE
    ELSE
      SELECT states.*
        INTO lrec_data.*
      FROM states
      WHERE states.stt_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "cities" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like cities.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION city_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE cities.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE cities.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT cities.* FROM cities"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_city_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_city_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_city_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "cities" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE cities.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE cities.*
FUNCTION city_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE cities.cts_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE cities.*

  TRY
    IF p_lock THEN
      SELECT cities.*
        INTO lrec_data.*
      FROM cities
      WHERE cities.cts_id = p_key
      FOR UPDATE
    ELSE
      SELECT cities.*
        INTO lrec_data.*
      FROM cities
      WHERE cities.cts_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the key in the "categories" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several categories editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE categories.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE categories.*
FUNCTION category_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE categories.ctgr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE categories.*

  TRY
    IF p_lock THEN
      SELECT categories.*
        INTO lrec_data.*
      FROM categories
      WHERE categories.ctgr_id = p_key
      FOR UPDATE
    ELSE
      SELECT categories.*
        INTO lrec_data.*
      FROM categories
      WHERE categories.ctgr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Get the next ui order in the "categories" table
#+
#+ @param p_key record key
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|NOTFOUND|error, error message, next ui order
FUNCTION category_get_next_uiorder()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  TRY
    SELECT MAX(categories.ctgr_uiorder)
      INTO i
    FROM categories
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, IIF(i IS NULL OR i==0, 1, i+1)
END FUNCTION

#+ Select a row identified by the key in the "categories" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several categories editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE categories.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE categories.*
FUNCTION category_select_row_by_name(p_key, p_lock)
  DEFINE
    p_key LIKE categories.ctgr_name,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE categories.*

  TRY
    IF p_lock THEN
      SELECT categories.*
        INTO lrec_data.*
      FROM categories
      WHERE categories.ctgr_name = p_key
      FOR UPDATE
    ELSE
      SELECT categories.*
        INTO lrec_data.*
      FROM categories
      WHERE categories.ctgr_name = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "categories" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like categories.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION category_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE categories.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT categories.* FROM categories"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_category_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_category_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_category_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "categories" table and return the primary key created
#+
#+ @param p_data - a row data LIKE categories.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, categories.ctgr_id
FUNCTION category_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.ctgr_id
  END IF

  TRY
    LET p_data.ctgr_id = 0
    INSERT INTO categories VALUES (p_data.*)
    LET p_data.ctgr_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.ctgr_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.ctgr_id
END FUNCTION

#+ Select a row identified by the primary key in the "accountstatus" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE accountstatus.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE accountstatus.*
FUNCTION accountstatus_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE accountstatus.accst_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE accountstatus.*

  TRY
    IF p_lock THEN
      SELECT accountstatus.*
        INTO lrec_data.*
      FROM accountstatus
      WHERE accountstatus.accst_id = p_key
      FOR UPDATE
    ELSE
      SELECT accountstatus.*
        INTO lrec_data.*
      FROM accountstatus
      WHERE accountstatus.accst_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "accountstatus" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like accountstatus.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION accountstatus_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE accountstatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE accountstatus.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT accountstatus.* FROM accountstatus"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_accountstatus_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_accountstatus_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_accountstatus_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "genders" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE genders.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE genders.*
FUNCTION gender_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE genders.gnd_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE genders.*

  TRY
    IF p_lock THEN
      SELECT genders.*
        INTO lrec_data.*
      FROM genders
      WHERE genders.gnd_id = p_key
      FOR UPDATE
    ELSE
      SELECT genders.*
        INTO lrec_data.*
      FROM genders
      WHERE genders.gnd_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the key in the "genders" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several genders editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE genders.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE genders.*
FUNCTION gender_select_row_by_name(p_key, p_lock)
  DEFINE
    p_key LIKE genders.gnd_name,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE genders.*

  TRY
    IF p_lock THEN
      SELECT genders.*
        INTO lrec_data.*
      FROM genders
      WHERE genders.gnd_name = p_key
      FOR UPDATE
    ELSE
      SELECT genders.*
        INTO lrec_data.*
      FROM genders
      WHERE genders.gnd_name = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "genders" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like genders.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION gender_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE genders.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE genders.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT genders.* FROM genders"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_gender_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_gender_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_gender_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaigngenders" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigngenders.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigngenders.cmpgen_campaign_id, campaigngenders.cmpgen_gender_id
FUNCTION campaigngenders_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigngenders.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpgen_campaign_id, p_data.cmpgen_gender_id
  END IF

  TRY
    INSERT INTO campaigngenders VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpgen_campaign_id, p_data.cmpgen_gender_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpgen_campaign_id, p_data.cmpgen_gender_id
END FUNCTION

#+ Delete all rows identified by the cmpgen_campaign_id in the "campaigngenders" table
#+
#+ @param p_key - cmpgen_campaign_id
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigngenders_delete_all_rows(p_key)
  DEFINE
    p_key LIKE campaigngenders.cmpgen_campaign_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaigngenders
      WHERE campaigngenders.cmpgen_campaign_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "brandcategories" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like brandcategories.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandcategories_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE brandcategories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brandcategories.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT brandcategories.* FROM brandcategories"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_brandcategories_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_brandcategories_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_brandcategories_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "brandcategories" table and return the primary key created
#+
#+ @param p_data - a row data LIKE brandcategories.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, brandcategories.brndcat_brand_id, brandcategories.brndcat_category_id
FUNCTION brandcategories_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE brandcategories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.brndcat_brand_id, p_data.brndcat_category_id
  END IF

  TRY
    INSERT INTO brandcategories VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.brndcat_brand_id, p_data.brndcat_category_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.brndcat_brand_id, p_data.brndcat_category_id
END FUNCTION

#+ Delete all rows identified by the brndcat_brand_id in the "brandcategories" table
#+
#+ @param p_key - brndcat_brand_id
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION brandcategories_delete_all_rows(p_key)
  DEFINE
    p_key LIKE brandcategories.brndcat_brand_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM brandcategories
      WHERE brandcategories.brndcat_brand_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "brands" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE brands.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE brands.*
FUNCTION brands_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE brands.brnd_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brands.*

  TRY
    IF p_lock THEN
      SELECT brands.*
        INTO lrec_data.*
      FROM brands
      WHERE brands.brnd_id = p_key
      FOR UPDATE
    ELSE
      SELECT brands.*
        INTO lrec_data.*
      FROM brands
      WHERE brands.brnd_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by its email in the "brands" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE brands.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE brands.*
FUNCTION brands_select_row_by_email(p_key, p_lock)
  DEFINE
    p_key LIKE brands.brnd_email,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brands.*

  TRY
    IF p_lock THEN
      SELECT brands.*
        INTO lrec_data.*
      FROM brands
      WHERE LOWER(brands.brnd_email) = LOWER(p_key)
      FOR UPDATE
    ELSE
      SELECT brands.*
        INTO lrec_data.*
      FROM brands
      WHERE LOWER(brands.brnd_email) = LOWER(p_key)
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "brands" table and return the primary key created
#+
#+ @param p_data - a row data LIKE brands.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, brands.brnd_id
FUNCTION brands_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE brands.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.brnd_id
  END IF

  TRY
    LET p_data.brnd_id = 0
    INSERT INTO brands VALUES (p_data.*)
    LET p_data.brnd_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.brnd_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.brnd_id
END FUNCTION

#+ Update a row identified by the primary key in the "brands" table
#+
#+ @param prec_data_old a row data LIKE brands.*
#+ @param prec_data_new a row data LIKE brands.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION brands_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE brands.*,
    prec_data_new RECORD LIKE brands.*,
    lrec_data RECORD LIKE brands.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL brands_select_row(prec_data_old.brnd_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE brands SET brands.* = prec_data_new.*
            WHERE brands.brnd_id = lrec_data.brnd_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "brands" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION brands_delete_row(p_key)
  DEFINE
    p_key LIKE brands.brnd_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM brands
      WHERE brands.brnd_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "brands" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like brands.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brands_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE brands.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brands.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT brands.* FROM brands"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_brands_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_brands_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_brands_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "pics" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE pics.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE pics.*
FUNCTION pics_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE pics.pic_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE pics.*

  LOCATE lrec_data.pic_value IN FILE
  TRY
    IF p_lock THEN
      SELECT pics.*
        INTO lrec_data.*
      FROM pics
      WHERE pics.pic_id = p_key
      FOR UPDATE
    ELSE
      SELECT pics.*
        INTO lrec_data.*
      FROM pics
      WHERE pics.pic_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "pics" table and return the primary key created
#+
#+ @param p_data - a row data LIKE pics.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, pics.pic_id
FUNCTION pics_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE pics.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.pic_id
  END IF

  TRY
    LET p_data.pic_id = 0
    INSERT INTO pics VALUES (p_data.*)
    LET p_data.pic_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.pic_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.pic_id
END FUNCTION

#+ Delete a row identified by the primary key in the "pics" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION pics_delete_row(p_key)
  DEFINE
    p_key LIKE pics.pic_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  IF p_key == C_PIC_DEFAULTAVATAR OR p_key == C_PIC_DEFAULTADDPHOTO OR p_key == C_PIC_DEFAULTADDBANNER THEN
    RETURN 0, NULL
  END IF
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  TRY
    DELETE FROM pics
      WHERE pics.pic_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "users" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE users.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE users.*
FUNCTION users_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE users.usr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE users.*

  TRY
    IF p_lock THEN
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_id = p_key
      FOR UPDATE
    ELSE
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by its email in the "users" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE users.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE users.*
FUNCTION users_select_row_by_email(p_key, p_lock)
  DEFINE
    p_key LIKE users.usr_email,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE users.*

  TRY
    IF p_lock THEN
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE LOWER(users.usr_email) = LOWER(p_key)
      FOR UPDATE
    ELSE
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE LOWER(users.usr_email) = LOWER(p_key)
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by its instagram user id in the "users" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE users.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE users.*
FUNCTION users_select_row_by_instagram_userid(p_key, p_lock)
  DEFINE
    p_key LIKE users.usr_instagram_userid,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE users.*

  TRY
    IF p_lock THEN
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_instagram_userid = p_key
      FOR UPDATE
    ELSE
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_instagram_userid = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by its instagram user name in the "users" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE users.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE users.*
FUNCTION users_select_row_by_instagram_username(p_key, p_lock)
  DEFINE
    p_key LIKE users.usr_instagram_username,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE users.*

  TRY
    IF p_lock THEN
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_instagram_username = p_key
      FOR UPDATE
    ELSE
      SELECT users.*
        INTO lrec_data.*
      FROM users
      WHERE users.usr_instagram_username = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "users" table and return the primary key created
#+
#+ @param p_data - a row data LIKE users.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, users.usr_id
FUNCTION users_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE users.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.usr_id
  END IF

  TRY
    LET p_data.usr_id = 0
    INSERT INTO users VALUES (p_data.*)
    LET p_data.usr_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.usr_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.usr_id
END FUNCTION

#+ Update a row identified by the primary key in the "users" table
#+
#+ @param prec_data_old a row data LIKE users.*
#+ @param prec_data_new a row data LIKE users.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION users_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE users.*,
    prec_data_new RECORD LIKE users.*,
    lrec_data RECORD LIKE users.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL users_select_row(prec_data_old.usr_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE users SET users.* = prec_data_new.*
            WHERE users.usr_id = lrec_data.usr_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "users" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION users_delete_row(p_key)
  DEFINE
    p_key LIKE users.usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM users
      WHERE users.usr_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "users" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like users.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION users_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE users.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE users.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT users.* FROM users"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_users_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_users_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_users_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get user metrics for an instagram account
#+
#+ @param pint_usr_id influencer id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION users_get_nb_followers(pint_usr_id LIKE users.usr_id)
  DEFINE
   lint_ret INTEGER,
   lstr_msg STRING,
   lrec_data RECORD LIKE usermetrics.*,
   lint_nb_followers LIKE usermetrics.usrmtc_followers_count

  INITIALIZE lint_nb_followers TO NULL
  CALL usermetrics_select_current_row_by_userid(pint_usr_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  IF lint_ret == 0 THEN
    LET lint_nb_followers = lrec_data.usrmtc_followers_count
  END IF
  RETURN lint_nb_followers
END FUNCTION

#+ Select a row identified by the primary key in the "currencies" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE currencies.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE currencies.*
FUNCTION currency_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE currencies.crr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE currencies.*

  TRY
    IF p_lock THEN
      SELECT currencies.*
        INTO lrec_data.*
      FROM currencies
      WHERE currencies.crr_id = p_key
      FOR UPDATE
    ELSE
      SELECT currencies.*
        INTO lrec_data.*
      FROM currencies
      WHERE currencies.crr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "currencies" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like currencies.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION currency_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE currencies.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE currencies.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT currencies.* FROM currencies"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_currency_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_currency_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_currency_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a currency symbol from the "currencies" table
#+
#+ @param p_key primary key
#+
#+ @returnType STRING
#+ @return     currency symbol
FUNCTION currency_get_symbol(p_key)
  DEFINE
    p_key LIKE currencies.crr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    l_data LIKE currencies.crr_symbol

  INITIALIZE l_data TO NULL
  TRY
    SELECT currencies.crr_symbol
      INTO l_data
    FROM currencies
    WHERE currencies.crr_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN l_data
END FUNCTION

#+ Select a row identified by the primary key in the "userpostprices" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several userpostprices editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE userpostprices.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE userpostprices.*
FUNCTION userpostprices_select_row(p_key, p_lock)
  DEFINE
    p_key RECORD
      usrpp_usr_id LIKE userpostprices.usrpp_usr_id,
      usrpp_posttype_id LIKE userpostprices.usrpp_posttype_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE userpostprices.*

  TRY
    IF p_lock THEN
      SELECT userpostprices.*
        INTO lrec_data.*
      FROM userpostprices
      WHERE userpostprices.usrpp_usr_id = p_key.usrpp_usr_id
        AND userpostprices.usrpp_posttype_id = p_key.usrpp_posttype_id
      FOR UPDATE
    ELSE
      SELECT userpostprices.*
        INTO lrec_data.*
      FROM userpostprices
      WHERE userpostprices.usrpp_usr_id = p_key.usrpp_usr_id
        AND userpostprices.usrpp_posttype_id = p_key.usrpp_posttype_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "userpostprices" table and return the primary key created
#+
#+ @param p_data - a row data LIKE userpostprices.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, userpostprices.usrpp_usr_id, userpostprices.usrpp_posttype_id
FUNCTION userpostprices_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE userpostprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.usrpp_usr_id, p_data.usrpp_posttype_id
  END IF

  TRY
    INSERT INTO userpostprices VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.usrpp_usr_id, p_data.usrpp_posttype_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.usrpp_usr_id, p_data.usrpp_posttype_id
END FUNCTION

#+ Update a row identified by the primary key in the "userpostprices" table
#+
#+ @param prec_data_old a row data LIKE userpostprices.*
#+ @param prec_data_new a row data LIKE userpostprices.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION userpostprices_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE userpostprices.*,
    prec_data_new RECORD LIKE userpostprices.*,
    lrec_data RECORD LIKE userpostprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL userpostprices_select_row(prec_data_old.usrpp_usr_id, prec_data_old.usrpp_posttype_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE userpostprices SET userpostprices.* = prec_data_new.*
            WHERE userpostprices.usrpp_usr_id = lrec_data.usrpp_usr_id
              AND userpostprices.usrpp_posttype_id = lrec_data.usrpp_posttype_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "userpostprices" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION userpostprices_delete_row(p_key)
  DEFINE
    p_key RECORD
      usrpp_usr_id LIKE userpostprices.usrpp_usr_id,
      usrpp_posttype_id LIKE userpostprices.usrpp_posttype_id
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM userpostprices
      WHERE userpostprices.usrpp_usr_id = p_key.usrpp_usr_id
        AND userpostprices.usrpp_posttype_id = p_key.usrpp_posttype_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "userpostprices" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like userpostprices.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostprices_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE userpostprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE userpostprices.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT userpostprices.* FROM userpostprices"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_userpostprices_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_userpostprices_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_userpostprices_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "backofficeusers" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE backofficeusers.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE backofficeusers.*
FUNCTION backofficeusers_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE backofficeusers.bousr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE backofficeusers.*

  TRY
    IF p_lock THEN
      SELECT backofficeusers.*
        INTO lrec_data.*
      FROM backofficeusers
      WHERE backofficeusers.bousr_id = p_key
      FOR UPDATE
    ELSE
      SELECT backofficeusers.*
        INTO lrec_data.*
      FROM backofficeusers
      WHERE backofficeusers.bousr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by its email in the "backofficeusers" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE backofficeusers.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE backofficeusers.*
FUNCTION backofficeusers_select_row_by_email(p_key, p_lock)
  DEFINE
    p_key LIKE backofficeusers.bousr_email,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE backofficeusers.*

  TRY
    IF p_lock THEN
      SELECT backofficeusers.*
        INTO lrec_data.*
      FROM backofficeusers
      WHERE LOWER(backofficeusers.bousr_email) = LOWER(p_key)
      FOR UPDATE
    ELSE
      SELECT backofficeusers.*
        INTO lrec_data.*
      FROM backofficeusers
      WHERE LOWER(backofficeusers.bousr_email) = LOWER(p_key)
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "backofficeusers" table and return the primary key created
#+
#+ @param p_data - a row data LIKE backofficeusers.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, backofficeusers.bousr_id
FUNCTION backofficeusers_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE backofficeusers.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.bousr_id
  END IF

  TRY
    LET p_data.bousr_id = 0
    INSERT INTO backofficeusers VALUES (p_data.*)
    LET p_data.bousr_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.bousr_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.bousr_id
END FUNCTION

#+ Update a row identified by the primary key in the "backofficeusers" table
#+
#+ @param prec_data_old a row data LIKE backofficeusers.*
#+ @param prec_data_new a row data LIKE backofficeusers.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION backofficeusers_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE backofficeusers.*,
    prec_data_new RECORD LIKE backofficeusers.*,
    lrec_data RECORD LIKE backofficeusers.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL backofficeusers_select_row(prec_data_old.bousr_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE backofficeusers SET backofficeusers.* = prec_data_new.*
            WHERE backofficeusers.bousr_id = lrec_data.bousr_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "backofficeusers" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION backofficeusers_delete_row(p_key)
  DEFINE
    p_key LIKE backofficeusers.bousr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM backofficeusers
      WHERE backofficeusers.bousr_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignshist" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignshist.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignshist.*
FUNCTION campaignshist_select_row_by_campaign_and_status(p_key, p_lock)
  DEFINE
    p_key RECORD
      cmph_campaign_id LIKE campaignshist.cmph_campaign_id,
      cmph_campaignstatus_id LIKE campaignshist.cmph_campaignstatus_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignshist.*

  TRY
    IF p_lock THEN
      SELECT campaignshist.*
        INTO lrec_data.*
      FROM campaignshist
      WHERE campaignshist.cmph_campaign_id = p_key.cmph_campaign_id
        AND campaignshist.cmph_campaignstatus_id = p_key.cmph_campaignstatus_id
      FOR UPDATE
    ELSE
      SELECT campaignshist.*
        INTO lrec_data.*
      FROM campaignshist
      WHERE campaignshist.cmph_campaign_id = p_key.cmph_campaign_id
        AND campaignshist.cmph_campaignstatus_id = p_key.cmph_campaignstatus_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaignshist" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignshist.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignshist.cmph_id
FUNCTION campaignshist_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmph_id
  END IF

  TRY
    LET p_data.cmph_id = 0
    INSERT INTO campaignshist VALUES (p_data.*)
    LET p_data.cmph_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmph_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmph_id
END FUNCTION

#+ Select a row identified by the primary key in the "campaigns" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaigns.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaigns.*
FUNCTION campaigns_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaigns.cmp_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigns.*

  TRY
    IF p_lock THEN
      SELECT campaigns.*
        INTO lrec_data.*
      FROM campaigns
      WHERE campaigns.cmp_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaigns.*
        INTO lrec_data.*
      FROM campaigns
      WHERE campaigns.cmp_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaigns" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigns.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigns.cmp_id
FUNCTION campaigns_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigns.*,
    lrec_datahist RECORD LIKE campaignshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmp_id
  END IF

  TRY
    LET p_data.cmp_id = 0
    INSERT INTO campaigns VALUES (p_data.*)
    LET p_data.cmp_id = SQLCA.SQLERRD[2]
    --insert into history
    INITIALIZE lrec_datahist.* TO NULL
    LET lrec_datahist.cmph_id = 0
    LET lrec_datahist.cmph_campaign_id = p_data.cmp_id
    LET lrec_datahist.cmph_campaignstatus_id = p_data.cmp_campaignstatus_id
    LET lrec_datahist.cmph_date = p_data.cmp_creationdate
    CALL campaignshist_insert_row(lrec_datahist.*)
      RETURNING lint_ret, lstr_msg, lrec_datahist.cmph_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmp_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmp_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaigns" table
#+
#+ @param prec_data_old a row data LIKE campaigns.*
#+ @param prec_data_new a row data LIKE campaigns.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaigns_update_row(prec_data_old, prec_data_new, p_timestamp)
  DEFINE
    prec_data_old RECORD LIKE campaigns.*,
    prec_data_new RECORD LIKE campaigns.*,
    p_timestamp LIKE campaignshist.cmph_date,
    lrec_data RECORD LIKE campaigns.*,
    lrec_datahist RECORD LIKE campaignshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaigns_select_row(prec_data_old.cmp_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaigns SET campaigns.* = prec_data_new.*
            WHERE campaigns.cmp_id = lrec_data.cmp_id
          --insert into history only if the campaign status has changed
          IF prec_data_old.cmp_campaignstatus_id <> prec_data_new.cmp_campaignstatus_id THEN
            INITIALIZE lrec_datahist.* TO NULL
            LET lrec_datahist.cmph_id = 0
            LET lrec_datahist.cmph_campaign_id = prec_data_new.cmp_id
            LET lrec_datahist.cmph_campaignstatus_id = prec_data_new.cmp_campaignstatus_id
            LET lrec_datahist.cmph_date = p_timestamp
            CALL campaignshist_insert_row(lrec_datahist.*)
            RETURNING lint_ret, lstr_msg, lrec_datahist.cmph_id
          END IF
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaigns" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigns_delete_row(p_key)
  DEFINE
    p_key LIKE campaigns.cmp_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaigns
      WHERE campaigns.cmp_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaigns" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaigns.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigns_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaigns.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigns.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaigns.* FROM campaigns"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaigns_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaigns_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaigns_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaigncategories" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaigncategories.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigncategories_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaigncategories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigncategories.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaigncategories.* FROM campaigncategories"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaigncategories_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaigncategories_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaigncategories_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaigncategories" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigncategories.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigncategories.cmpcat_campaign_id, campaigncategories.cmpcat_category_id
FUNCTION campaigncategories_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigncategories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpcat_campaign_id, p_data.cmpcat_category_id
  END IF

  TRY
    INSERT INTO campaigncategories VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpcat_campaign_id, p_data.cmpcat_category_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpcat_campaign_id, p_data.cmpcat_category_id
END FUNCTION

#+ Delete all rows identified by the cmpcat_campaign_id in the "campaigncategories" table
#+
#+ @param p_key - cmpcat_campaign_id
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigncategories_delete_all_rows(p_key)
  DEFINE
    p_key LIKE campaigncategories.cmpcat_campaign_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaigncategories
      WHERE campaigncategories.cmpcat_campaign_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the key in the "posttypes" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several categories editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE posttypes.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE posttypes.*
FUNCTION posttype_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE posttypes.pstt_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE posttypes.*

  TRY
    IF p_lock THEN
      SELECT posttypes.*
        INTO lrec_data.*
      FROM posttypes
      WHERE posttypes.pstt_id = p_key
      FOR UPDATE
    ELSE
      SELECT posttypes.*
        INTO lrec_data.*
      FROM posttypes
      WHERE posttypes.pstt_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the key in the "posttypes" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several categories editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE posttypes.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE posttypes.*
FUNCTION posttype_select_row_by_name(p_key, p_lock)
  DEFINE
    p_key LIKE posttypes.pstt_name,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE posttypes.*

  TRY
    IF p_lock THEN
      SELECT posttypes.*
        INTO lrec_data.*
      FROM posttypes
      WHERE posttypes.pstt_name = p_key
      FOR UPDATE
    ELSE
      SELECT posttypes.*
        INTO lrec_data.*
      FROM posttypes
      WHERE posttypes.pstt_name = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "posttypes" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like posttypes.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION posttype_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE posttypes.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT posttypes.* FROM posttypes"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_posttype_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_posttype_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_posttype_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignposttypes" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaignposttypes editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignposttypes.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignposttypes.*
FUNCTION campaignposttypes_select_row(p_key, p_lock)
  DEFINE
    p_key RECORD
      cmppst_campaign_id LIKE campaignposttypes.cmppst_campaign_id,
      cmppst_posttype_id LIKE campaignposttypes.cmppst_posttype_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposttypes.*

  TRY
    IF p_lock THEN
      SELECT campaignposttypes.*
        INTO lrec_data.*
      FROM campaignposttypes
      WHERE campaignposttypes.cmppst_campaign_id = p_key.cmppst_campaign_id
        AND campaignposttypes.cmppst_posttype_id = p_key.cmppst_posttype_id
      FOR UPDATE
    ELSE
      SELECT campaignposttypes.*
        INTO lrec_data.*
      FROM campaignposttypes
      WHERE campaignposttypes.cmppst_campaign_id = p_key.cmppst_campaign_id
        AND campaignposttypes.cmppst_posttype_id = p_key.cmppst_posttype_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "campaignposttypes" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignposttypes.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignposttypes_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposttypes.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignposttypes.* FROM campaignposttypes"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignposttypes_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignposttypes_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignposttypes_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaignposttypes" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignposttypes.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignposttypes.cmppst_campaign_id, campaignposttypes.cmppst_posttype_id
FUNCTION campaignposttypes_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignposttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmppst_campaign_id, p_data.cmppst_posttype_id
  END IF

  TRY
    INSERT INTO campaignposttypes VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmppst_campaign_id, p_data.cmppst_posttype_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmppst_campaign_id, p_data.cmppst_posttype_id
END FUNCTION

#+ Delete all rows identified by the cmppst_campaign_id in the "campaignposttypes" table
#+
#+ @param p_key - cmppst_campaign_id
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignposttypes_delete_all_rows(p_key)
  DEFINE
    p_key LIKE campaignposttypes.cmppst_campaign_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignposttypes
      WHERE campaignposttypes.cmppst_campaign_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignphotos" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignphotos.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignphotos_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignphotos.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignphotos.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignphotos.* FROM campaignphotos"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignphotos_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignphotos_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignphotos_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaignphotos" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignphotos.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignphotos.cmpph_campaign_id, campaignphotos.cmpph_pic_id
FUNCTION campaignphotos_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignphotos.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpph_campaign_id, p_data.cmpph_pic_id
  END IF

  TRY
    INSERT INTO campaignphotos VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpph_campaign_id, p_data.cmpph_pic_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpph_campaign_id, p_data.cmpph_pic_id
END FUNCTION

#+ Delete all rows identified by the key in the "campaignphotos" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignphotos_delete_all_rows(p_key)
  DEFINE
    p_key LIKE campaignphotos.cmpph_campaign_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    larec_data DYNAMIC ARRAY OF RECORD LIKE campaignphotos.*,
    i INTEGER

  CALL campaignphotos_fetch_all_rows(SFMT("WHERE campaignphotos.cmpph_campaign_id = %1", p_key), NULL, larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  TRY
    DELETE FROM campaignphotos
      WHERE campaignphotos.cmpph_campaign_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL pics_delete_row(larec_data[i].cmpph_pic_id)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN EXIT FOR END IF
    END FOR
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "postdurations" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE postdurations.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE postdurations.*
FUNCTION postduration_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE postdurations.pstdr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE postdurations.*

  TRY
    IF p_lock THEN
      SELECT postdurations.*
        INTO lrec_data.*
      FROM postdurations
      WHERE postdurations.pstdr_id = p_key
      FOR UPDATE
    ELSE
      SELECT postdurations.*
        INTO lrec_data.*
      FROM postdurations
      WHERE postdurations.pstdr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "postdurations" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like postdurations.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION postduration_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE postdurations.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE postdurations.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT postdurations.* FROM postdurations"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_duration_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_duration_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_duration_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignstatus" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignstatus.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignstatus.*
FUNCTION campaignstatus_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaignstatus.cmpst_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignstatus.*

  TRY
    IF p_lock THEN
      SELECT campaignstatus.*
        INTO lrec_data.*
      FROM campaignstatus
      WHERE campaignstatus.cmpst_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaignstatus.*
        INTO lrec_data.*
      FROM campaignstatus
      WHERE campaignstatus.cmpst_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select all rows in the "campaignstatus" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignstatus.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignstatus_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignstatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignstatus.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignstatus.* FROM campaignstatus"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignstatus_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignstatus_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignstatus_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaigntags" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaigntags.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigntags_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaigntags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigntags.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaigntags.* FROM campaigntags"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaigntags_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaigntags_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaigntags_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaigntags" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigntags.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigntags.cmptg_campaign_id, campaigntags.cmptg_tag_id
FUNCTION campaigntags_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigntags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmptg_campaign_id, p_data.cmptg_tag_id
  END IF

  TRY
    INSERT INTO campaigntags VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmptg_campaign_id, p_data.cmptg_tag_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmptg_campaign_id, p_data.cmptg_tag_id
END FUNCTION

#+ Delete all rows identified by the cmptg_campaign_id in the "campaigntags" table
#+
#+ @param p_key - cmptg_campaign_id
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigntags_delete_all_rows(p_key)
  DEFINE
    p_key LIKE campaigntags.cmptg_campaign_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  TRY
    DELETE FROM campaigntags
      WHERE campaigntags.cmptg_campaign_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "tags" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several tags editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE tags.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE tags.*
FUNCTION tags_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE tags.tag_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE tags.*

  TRY
    IF p_lock THEN
      SELECT tags.*
        INTO lrec_data.*
      FROM tags
      WHERE tags.tag_id = p_key
      FOR UPDATE
    ELSE
      SELECT tags.*
        INTO lrec_data.*
      FROM tags
      WHERE tags.tag_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "tags" table and return the primary key created
#+
#+ @param p_data - a row data LIKE tags.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, tags.tag_id
FUNCTION tags_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE tags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.tag_id
  END IF

  TRY
    LET p_data.tag_id = 0
    INSERT INTO tags VALUES (p_data.*)
    LET p_data.tag_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.tag_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.tag_id
END FUNCTION

#+ Update a row identified by the primary key in the "tags" table
#+
#+ @param prec_data_old a row data LIKE tags.*
#+ @param prec_data_new a row data LIKE tags.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION tags_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE tags.*,
    prec_data_new RECORD LIKE tags.*,
    lrec_data RECORD LIKE tags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL tags_select_row(prec_data_old.tag_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE tags SET tags.* = prec_data_new.*
            WHERE tags.tag_id = lrec_data.tag_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "tags" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION tags_delete_row(p_key)
  DEFINE
    p_key LIKE tags.tag_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM tags
      WHERE tags.tag_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "tags" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like tags.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION tags_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE tags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE tags.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT tags.* FROM tags"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_tags_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_tags_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_tags_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the key in the "tags" table
#+
#+ @param p_key record key
#+ @param p_lock Indicate if a lock is used in order to prevent several tags editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE tags.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE tags.*
FUNCTION tags_select_row_by_name_and_type(p_key, p_lock)
  DEFINE
    p_key RECORD
      tag_name LIKE tags.tag_name,
      tag_type_id LIKE tags.tag_type_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE tags.*

  TRY
    IF p_lock THEN
      SELECT tags.*
        INTO lrec_data.*
      FROM tags
      WHERE tags.tag_name = p_key.tag_name
        AND tags.tag_type_id = p_key.tag_type_id
      FOR UPDATE
    ELSE
      SELECT tags.*
        INTO lrec_data.*
      FROM tags
      WHERE tags.tag_name = p_key.tag_name
        AND tags.tag_type_id = p_key.tag_type_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the influencer id in the "usermetrics" table
#+
#+ @param p_key influencer id
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE usermetrics.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE usermetrics.*
FUNCTION usermetrics_select_current_row_by_userid(p_key, p_lock)
  DEFINE
    p_key LIKE usermetrics.usrmtc_usr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE usermetrics.*

  TRY
    IF p_lock THEN
      SELECT usermetrics.*
        INTO lrec_data.*
      FROM usermetrics
      WHERE usermetrics.usrmtc_usr_id = p_key
      AND CURRENT BETWEEN usermetrics.usrmtc_bdate AND usermetrics.usrmtc_edate
      FOR UPDATE
    ELSE
      SELECT usermetrics.*
        INTO lrec_data.*
      FROM usermetrics
      WHERE usermetrics.usrmtc_usr_id = p_key
      AND CURRENT BETWEEN usermetrics.usrmtc_bdate AND usermetrics.usrmtc_edate
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the primary key in the "usermetrics" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE usermetrics.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE usermetrics.*
FUNCTION usermetrics_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE usermetrics.usrmtc_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE usermetrics.*

  TRY
    IF p_lock THEN
      SELECT usermetrics.*
        INTO lrec_data.*
      FROM usermetrics
      WHERE usermetrics.usrmtc_id = p_key
      FOR UPDATE
    ELSE
      SELECT usermetrics.*
        INTO lrec_data.*
      FROM usermetrics
      WHERE usermetrics.usrmtc_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "usermetrics" table and return the primary key created
#+
#+ @param p_data - a row data LIKE usermetrics.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, usermetrics.usrmtc_id
FUNCTION usermetrics_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE usermetrics.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.usrmtc_id
  END IF

  TRY
    LET p_data.usrmtc_id = 0
    INSERT INTO usermetrics VALUES (p_data.*)
    LET p_data.usrmtc_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.usrmtc_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.usrmtc_id
END FUNCTION

#+ Update a row identified by the primary key in the "usermetrics" table
#+
#+ @param prec_data_old a row data LIKE usermetrics.*
#+ @param prec_data_new a row data LIKE usermetrics.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION usermetrics_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE usermetrics.*,
    prec_data_new RECORD LIKE usermetrics.*,
    lrec_data RECORD LIKE usermetrics.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL usermetrics_select_row(prec_data_old.usrmtc_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE usermetrics SET usermetrics.* = prec_data_new.*
            WHERE usermetrics.usrmtc_id = lrec_data.usrmtc_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "usersocialnetworks" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several usersocialnetworks editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE usersocialnetworks.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE usersocialnetworks.*
FUNCTION usersocialnetworks_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE usersocialnetworks.usrscl_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE usersocialnetworks.*

  TRY
    IF p_lock THEN
      SELECT usersocialnetworks.*
        INTO lrec_data.*
      FROM usersocialnetworks
      WHERE usersocialnetworks.usrscl_id = p_key
      FOR UPDATE
    ELSE
      SELECT usersocialnetworks.*
        INTO lrec_data.*
      FROM usersocialnetworks
      WHERE usersocialnetworks.usrscl_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "usersocialnetworks" table and return the primary key created
#+
#+ @param p_data - a row data LIKE usersocialnetworks.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, usersocialnetworks.usrscl_id
FUNCTION usersocialnetworks_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE usersocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.usrscl_id
  END IF

  TRY
    LET p_data.usrscl_id = 0
    INSERT INTO usersocialnetworks VALUES (p_data.*)
    LET p_data.usrscl_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.usrscl_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.usrscl_id
END FUNCTION

#+ Update a row identified by the primary key in the "usersocialnetworks" table
#+
#+ @param prec_data_old a row data LIKE usersocialnetworks.*
#+ @param prec_data_new a row data LIKE usersocialnetworks.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION usersocialnetworks_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE usersocialnetworks.*,
    prec_data_new RECORD LIKE usersocialnetworks.*,
    lrec_data RECORD LIKE usersocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL usersocialnetworks_select_row(prec_data_old.usrscl_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE usersocialnetworks SET usersocialnetworks.* = prec_data_new.*
            WHERE usersocialnetworks.usrscl_id = lrec_data.usrscl_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "usersocialnetworks" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION usersocialnetworks_delete_row(p_key)
  DEFINE
    p_key LIKE usersocialnetworks.usrscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM usersocialnetworks
      WHERE usersocialnetworks.usrscl_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "usersocialnetworks" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like usersocialnetworks.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION usersocialnetworks_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE usersocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE usersocialnetworks.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT usersocialnetworks.* FROM usersocialnetworks"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_usersocialnetworks_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_usersocialnetworks_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_usersocialnetworks_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "socialnetworks" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like socialnetworks.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION socialnetwork_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE socialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE socialnetworks.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT socialnetworks.* FROM socialnetworks"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_socialnetwork_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_socialnetwork_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_socialnetwork_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "socialnetworks" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several socialnetworks editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE socialnetworks.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE socialnetworks.*
FUNCTION socialnetwork_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE socialnetworks.scl_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE socialnetworks.*

  TRY
    IF p_lock THEN
      SELECT socialnetworks.*
        INTO lrec_data.*
      FROM socialnetworks
      WHERE socialnetworks.scl_id = p_key
      FOR UPDATE
    ELSE
      SELECT socialnetworks.*
        INTO lrec_data.*
      FROM socialnetworks
      WHERE socialnetworks.scl_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the primary key in the "campaigncountries" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaigncountries editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaigncountries.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaigncountries.*
FUNCTION campaigncountries_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaigncountries.cmpcntr_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigncountries.*

  TRY
    IF p_lock THEN
      SELECT campaigncountries.*
        INTO lrec_data.*
      FROM campaigncountries
      WHERE campaigncountries.cmpcntr_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaigncountries.*
        INTO lrec_data.*
      FROM campaigncountries
      WHERE campaigncountries.cmpcntr_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaigncountries" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigncountries.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigncountries.cmpcntr_id
FUNCTION campaigncountries_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigncountries.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpcntr_id
  END IF

  TRY
    LET p_data.cmpcntr_id = 0
    INSERT INTO campaigncountries VALUES (p_data.*)
    LET p_data.cmpcntr_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpcntr_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpcntr_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaigncountries" table
#+
#+ @param prec_data_old a row data LIKE campaigncountries.*
#+ @param prec_data_new a row data LIKE campaigncountries.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaigncountries_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE campaigncountries.*,
    prec_data_new RECORD LIKE campaigncountries.*,
    lrec_data RECORD LIKE campaigncountries.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaigncountries_select_row(prec_data_old.cmpcntr_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaigncountries SET campaigncountries.* = prec_data_new.*
            WHERE campaigncountries.cmpcntr_id = lrec_data.cmpcntr_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaigncountries" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigncountries_delete_row(p_key)
  DEFINE
    p_key LIKE campaigncountries.cmpcntr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaigncountries
      WHERE campaigncountries.cmpcntr_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaigncountries" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaigncountries.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigncountries_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaigncountries.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigncountries.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaigncountries.* FROM campaigncountries"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaigncountries_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaigncountries_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaigncountries_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignstates" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaignstates editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignstates.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignstates.*
FUNCTION campaignstates_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaignstates.cmpstt_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignstates.*

  TRY
    IF p_lock THEN
      SELECT campaignstates.*
        INTO lrec_data.*
      FROM campaignstates
      WHERE campaignstates.cmpstt_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaignstates.*
        INTO lrec_data.*
      FROM campaignstates
      WHERE campaignstates.cmpstt_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaignstates" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignstates.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignstates.cmpstt_id
FUNCTION campaignstates_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignstates.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpstt_id
  END IF

  TRY
    LET p_data.cmpstt_id = 0
    INSERT INTO campaignstates VALUES (p_data.*)
    LET p_data.cmpstt_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpstt_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpstt_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaignstates" table
#+
#+ @param prec_data_old a row data LIKE campaignstates.*
#+ @param prec_data_new a row data LIKE campaignstates.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignstates_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE campaignstates.*,
    prec_data_new RECORD LIKE campaignstates.*,
    lrec_data RECORD LIKE campaignstates.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaignstates_select_row(prec_data_old.cmpstt_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaignstates SET campaignstates.* = prec_data_new.*
            WHERE campaignstates.cmpstt_id = lrec_data.cmpstt_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaignstates" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignstates_delete_row(p_key)
  DEFINE
    p_key LIKE campaignstates.cmpstt_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignstates
      WHERE campaignstates.cmpstt_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignstates" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignstates.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignstates_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignstates.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignstates.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignstates.* FROM campaignstates"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignstates_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignstates_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignstates_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaigncities" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaigncities editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaigncities.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaigncities.*
FUNCTION campaigncities_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaigncities.cmpcts_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigncities.*

  TRY
    IF p_lock THEN
      SELECT campaigncities.*
        INTO lrec_data.*
      FROM campaigncities
      WHERE campaigncities.cmpcts_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaigncities.*
        INTO lrec_data.*
      FROM campaigncities
      WHERE campaigncities.cmpcts_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaigncities" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaigncities.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaigncities.cmpcts_id
FUNCTION campaigncities_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaigncities.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpcts_id
  END IF

  TRY
    LET p_data.cmpcts_id = 0
    INSERT INTO campaigncities VALUES (p_data.*)
    LET p_data.cmpcts_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpcts_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpcts_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaigncities" table
#+
#+ @param prec_data_old a row data LIKE campaigncities.*
#+ @param prec_data_new a row data LIKE campaigncities.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaigncities_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE campaigncities.*,
    prec_data_new RECORD LIKE campaigncities.*,
    lrec_data RECORD LIKE campaigncities.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaigncities_select_row(prec_data_old.cmpcts_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaigncities SET campaigncities.* = prec_data_new.*
            WHERE campaigncities.cmpcts_id = lrec_data.cmpcts_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaigncities" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaigncities_delete_row(p_key)
  DEFINE
    p_key LIKE campaigncities.cmpcts_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaigncities
      WHERE campaigncities.cmpcts_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaigncities" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaigncities.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigncities_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaigncities.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaigncities.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaigncities.* FROM campaigncities"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaigncities_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaigncities_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaigncities_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignuserlist" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaignuserlist editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignuserlist.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignuserlist.*
FUNCTION campaignuserlist_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaignuserlist.cmpusrl_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignuserlist.*

  TRY
    IF p_lock THEN
      SELECT campaignuserlist.*
        INTO lrec_data.*
      FROM campaignuserlist
      WHERE campaignuserlist.cmpusrl_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaignuserlist.*
        INTO lrec_data.*
      FROM campaignuserlist
      WHERE campaignuserlist.cmpusrl_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the primary key in the "campaignuserlist" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaignuserlist editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignuserlist.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignuserlist.*
FUNCTION campaignuserlist_select_row_by_campaign_and_user(p_key, p_lock)
  DEFINE
    p_key RECORD
      cmpusrl_campaign_id LIKE campaignuserlist.cmpusrl_campaign_id,
      cmpusrl_user_id LIKE campaignuserlist.cmpusrl_user_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignuserlist.*

  TRY
    IF p_lock THEN
      SELECT campaignuserlist.*
        INTO lrec_data.*
      FROM campaignuserlist
      WHERE campaignuserlist.cmpusrl_campaign_id = p_key.cmpusrl_campaign_id
        AND campaignuserlist.cmpusrl_user_id = p_key.cmpusrl_user_id
      FOR UPDATE
    ELSE
      SELECT campaignuserlist.*
        INTO lrec_data.*
      FROM campaignuserlist
      WHERE campaignuserlist.cmpusrl_campaign_id = p_key.cmpusrl_campaign_id
        AND campaignuserlist.cmpusrl_user_id = p_key.cmpusrl_user_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaignuserlist" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignuserlist.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignuserlist.cmpusrl_id
FUNCTION campaignuserlist_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpusrl_id
  END IF

  TRY
    LET p_data.cmpusrl_id = 0
    INSERT INTO campaignuserlist VALUES (p_data.*)
    LET p_data.cmpusrl_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpusrl_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpusrl_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaignuserlist" table
#+
#+ @param prec_data_old a row data LIKE campaignuserlist.*
#+ @param prec_data_new a row data LIKE campaignuserlist.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignuserlist_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE campaignuserlist.*,
    prec_data_new RECORD LIKE campaignuserlist.*,
    lrec_data RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaignuserlist_select_row(prec_data_old.cmpusrl_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaignuserlist SET campaignuserlist.* = prec_data_new.*
            WHERE campaignuserlist.cmpusrl_id = lrec_data.cmpusrl_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaignuserlist" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignuserlist_delete_row(p_key)
  DEFINE
    p_key LIKE campaignuserlist.cmpusrl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignuserlist
      WHERE campaignuserlist.cmpusrl_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignuserlist" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignuserlist.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignuserlist_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignuserlist.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignuserlist.* FROM campaignuserlist"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignuserlist_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignuserlist_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignuserlist_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "campaignuserprices" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several campaignuserprices editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignuserprices.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignuserprices.*
FUNCTION campaignuserprices_select_row(p_key, p_lock)
  DEFINE
    p_key RECORD
      cmpusrp_campaign_id LIKE campaignuserprices.cmpusrp_campaign_id,
      cmpusrp_usr_id LIKE campaignuserprices.cmpusrp_usr_id,
      cmpusrp_posttype_id LIKE campaignuserprices.cmpusrp_posttype_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignuserprices.*

  TRY
    IF p_lock THEN
      SELECT campaignuserprices.*
        INTO lrec_data.*
      FROM campaignuserprices
      WHERE campaignuserprices.cmpusrp_campaign_id = p_key.cmpusrp_campaign_id
        AND campaignuserprices.cmpusrp_usr_id = p_key.cmpusrp_usr_id
        AND campaignuserprices.cmpusrp_posttype_id = p_key.cmpusrp_posttype_id
      FOR UPDATE
    ELSE
      SELECT campaignuserprices.*
        INTO lrec_data.*
      FROM campaignuserprices
      WHERE campaignuserprices.cmpusrp_campaign_id = p_key.cmpusrp_campaign_id
        AND campaignuserprices.cmpusrp_usr_id = p_key.cmpusrp_usr_id
        AND campaignuserprices.cmpusrp_posttype_id = p_key.cmpusrp_posttype_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaignuserprices" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignuserprices.*
#+
#+ @returnType INTEGER, STRING, INTEGER, INTEGER, INTEGER
#+ @return     0|FAILURE, error message, campaignuserprices.cmpusrp_campaign_id, campaignuserprices.cmpusrp_usr_id, campaignuserprices.cmpusrp_posttype_id
FUNCTION campaignuserprices_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignuserprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpusrp_campaign_id, p_data.cmpusrp_usr_id, p_data.cmpusrp_posttype_id
  END IF

  TRY
    INSERT INTO campaignuserprices VALUES (p_data.*)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpusrp_campaign_id, p_data.cmpusrp_usr_id, p_data.cmpusrp_posttype_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpusrp_campaign_id, p_data.cmpusrp_usr_id, p_data.cmpusrp_posttype_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaignuserprices" table
#+
#+ @param prec_data_old a row data LIKE campaignuserprices.*
#+ @param prec_data_new a row data LIKE campaignuserprices.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignuserprices_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE campaignuserprices.*,
    prec_data_new RECORD LIKE campaignuserprices.*,
    lrec_data RECORD LIKE campaignuserprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaignuserprices_select_row(prec_data_old.cmpusrp_campaign_id, prec_data_old.cmpusrp_usr_id, prec_data_old.cmpusrp_posttype_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaignuserprices SET campaignuserprices.* = prec_data_new.*
            WHERE campaignuserprices.cmpusrp_campaign_id = lrec_data.cmpusrp_campaign_id
              AND campaignuserprices.cmpusrp_usr_id = lrec_data.cmpusrp_usr_id
              AND campaignuserprices.cmpusrp_posttype_id = lrec_data.cmpusrp_posttype_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaignuserprices" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignuserprices_delete_row(p_key)
  DEFINE
    p_key RECORD
      cmpusrp_campaign_id LIKE campaignuserprices.cmpusrp_campaign_id,
      cmpusrp_usr_id LIKE campaignuserprices.cmpusrp_usr_id,
      cmpusrp_posttype_id LIKE campaignuserprices.cmpusrp_posttype_id
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignuserprices
      WHERE campaignuserprices.cmpusrp_campaign_id = p_key.cmpusrp_campaign_id
        AND campaignuserprices.cmpusrp_usr_id = p_key.cmpusrp_usr_id
        AND campaignuserprices.cmpusrp_posttype_id = p_key.cmpusrp_posttype_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignuserprices" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignuserprices.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignuserprices_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignuserprices.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignuserprices.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignuserprices.* FROM campaignuserprices"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignuserprices_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignuserprices_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignuserprices_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete all rows identified by the campaign and the influencer in the "campaignuserprices" table
#+
#+ @param p_key - campaign and influencer ids
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
FUNCTION campaignuserprices_delete_all_rows(p_key)
  DEFINE
    p_key RECORD
      cmpusrp_campaign_id LIKE campaignuserprices.cmpusrp_campaign_id,
      cmpusrp_usr_id LIKE campaignuserprices.cmpusrp_usr_id
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignuserprices
      WHERE campaignuserprices.cmpusrp_campaign_id = p_key.cmpusrp_campaign_id
        AND campaignuserprices.cmpusrp_usr_id = p_key.cmpusrp_usr_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a row in the "campaignpostshist" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignposts.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignpostshist.cmpposth_id
FUNCTION campaignpostshist_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignpostshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmpposth_id
  END IF

  TRY
    LET p_data.cmpposth_id = 0
    INSERT INTO campaignpostshist VALUES (p_data.*)
    LET p_data.cmpposth_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmpposth_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmpposth_id
END FUNCTION

#+ Select a row identified by the primary key in the "campaignposts" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignposts.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignposts.*
FUNCTION campaignposts_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE campaignposts.cmppost_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposts.*

  TRY
    IF p_lock THEN
      SELECT campaignposts.*
        INTO lrec_data.*
      FROM campaignposts
      WHERE campaignposts.cmppost_id = p_key
      FOR UPDATE
    ELSE
      SELECT campaignposts.*
        INTO lrec_data.*
      FROM campaignposts
      WHERE campaignposts.cmppost_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Select a row identified by the primary key in the "campaignposts" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several users editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE campaignposts.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE campaignposts.*
FUNCTION campaignposts_select_row_by_campaign_and_user_and_posttype(p_key, p_lock)
  DEFINE
    p_key RECORD
      cmppost_campaign_id LIKE campaignposts.cmppost_campaign_id,
      cmppost_usr_id LIKE campaignposts.cmppost_usr_id,
      cmppost_posttype_id LIKE campaignposts.cmppost_posttype_id
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposts.*

  TRY
    IF p_lock THEN
      SELECT campaignposts.*
        INTO lrec_data.*
      FROM campaignposts
      WHERE campaignposts.cmppost_campaign_id = p_key.cmppost_campaign_id
      AND campaignposts.cmppost_usr_id = p_key.cmppost_usr_id
      AND campaignposts.cmppost_posttype_id = p_key.cmppost_posttype_id
      FOR UPDATE
    ELSE
      SELECT campaignposts.*
        INTO lrec_data.*
      FROM campaignposts
      WHERE campaignposts.cmppost_campaign_id = p_key.cmppost_campaign_id
      AND campaignposts.cmppost_usr_id = p_key.cmppost_usr_id
      AND campaignposts.cmppost_posttype_id = p_key.cmppost_posttype_id
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "campaignposts" table and return the primary key created
#+
#+ @param p_data - a row data LIKE campaignposts.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, campaignposts.cmppost_id
FUNCTION campaignposts_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE campaignposts.*,
    lrec_datahist RECORD LIKE campaignpostshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.cmppost_id
  END IF

  TRY
    LET p_data.cmppost_id = 0
    INSERT INTO campaignposts VALUES (p_data.*)
    LET p_data.cmppost_id = SQLCA.SQLERRD[2]
    --insert into history
    INITIALIZE lrec_datahist.* TO NULL
    LET lrec_datahist.cmpposth_id = 0
    LET lrec_datahist.cmpposth_campaignpost_id = p_data.cmppost_id
    LET lrec_datahist.cmpposth_status_id = p_data.cmppost_status_id
    LET lrec_datahist.cmpposth_statusdate = p_data.cmppost_creationdate
    CALL campaignpostshist_insert_row(lrec_datahist.*)
      RETURNING lint_ret, lstr_msg, lrec_datahist.cmpposth_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.cmppost_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.cmppost_id
END FUNCTION

#+ Update a row identified by the primary key in the "campaignposts" table
#+
#+ @param prec_data_old a row data LIKE campaignposts.*
#+ @param prec_data_new a row data LIKE campaignposts.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignposts_update_row(prec_data_old, prec_data_new, p_timestamp)
  DEFINE
    prec_data_old RECORD LIKE campaignposts.*,
    prec_data_new RECORD LIKE campaignposts.*,
    p_timestamp LIKE campaignpostshist.cmpposth_statusdate,
    lrec_data RECORD LIKE campaignposts.*,
    lrec_datahist RECORD LIKE campaignpostshist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL campaignposts_select_row(prec_data_old.cmppost_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE campaignposts SET campaignposts.* = prec_data_new.*
            WHERE campaignposts.cmppost_id = lrec_data.cmppost_id
          --insert into history only if the campaignpost status has changed
          IF prec_data_old.cmppost_status_id <> prec_data_new.cmppost_status_id THEN
            INITIALIZE lrec_datahist.* TO NULL
            LET lrec_datahist.cmpposth_id = 0
            LET lrec_datahist.cmpposth_campaignpost_id = prec_data_new.cmppost_id
            LET lrec_datahist.cmpposth_status_id = prec_data_new.cmppost_status_id
            LET lrec_datahist.cmpposth_statusdate = p_timestamp
            CALL campaignpostshist_insert_row(lrec_datahist.*)
              RETURNING lint_ret, lstr_msg, lrec_datahist.cmpposth_id
          END IF
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "campaignposts" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION campaignposts_delete_row(p_key)
  DEFINE
    p_key LIKE campaignposts.cmppost_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM campaignpostshist
      WHERE campaignpostshist.cmpposth_campaignpost_id = p_key
    DELETE FROM campaignposts
      WHERE campaignposts.cmppost_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignposts" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignposts.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignposts_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignposts.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposts.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignposts.* FROM campaignposts"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignposts_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignposts_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignposts_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "campaignpoststatus" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like campaignpoststatus.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpoststatus_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE campaignpoststatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignpoststatus.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT campaignpoststatus.* FROM campaignpoststatus"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_campaignpoststatus_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_campaignpoststatus_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_campaignpoststatus_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select a row identified by the primary key in the "brandsocialnetworks" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several brandsocialnetworks editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE brandsocialnetworks.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE brandsocialnetworks.*
FUNCTION brandsocialnetworks_select_row(p_key, p_lock)
  DEFINE
    p_key LIKE brandsocialnetworks.brndscl_id,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brandsocialnetworks.*

  TRY
    IF p_lock THEN
      SELECT brandsocialnetworks.*
        INTO lrec_data.*
      FROM brandsocialnetworks
      WHERE brandsocialnetworks.brndscl_id = p_key
      FOR UPDATE
    ELSE
      SELECT brandsocialnetworks.*
        INTO lrec_data.*
      FROM brandsocialnetworks
      WHERE brandsocialnetworks.brndscl_id = p_key
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Insert a row in the "brandsocialnetworks" table and return the primary key created
#+
#+ @param p_data - a row data LIKE brandsocialnetworks.*
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|FAILURE, error message, brandsocialnetworks.brndscl_id
FUNCTION brandsocialnetworks_insert_row(p_data)
  DEFINE
    p_data RECORD LIKE brandsocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, p_data.brndscl_id
  END IF

  TRY
    LET p_data.brndscl_id = 0
    INSERT INTO brandsocialnetworks VALUES (p_data.*)
    LET p_data.brndscl_id = SQLCA.SQLERRD[2]
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, p_data.brndscl_id
  END IF

  RETURN lint_ret, lstr_msg, p_data.brndscl_id
END FUNCTION

#+ Update a row identified by the primary key in the "brandsocialnetworks" table
#+
#+ @param prec_data_old a row data LIKE brandsocialnetworks.*
#+ @param prec_data_new a row data LIKE brandsocialnetworks.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION brandsocialnetworks_update_row(prec_data_old, prec_data_new)
  DEFINE
    prec_data_old RECORD LIKE brandsocialnetworks.*,
    prec_data_new RECORD LIKE brandsocialnetworks.*,
    lrec_data RECORD LIKE brandsocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    --lock the current record
    CALL brandsocialnetworks_select_row(prec_data_old.brndscl_id, TRUE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN NOTFOUND
        LET lstr_msg = %"Record has been deleted since edition started"
      WHEN 0
        IF lrec_data.* == prec_data_old.* THEN --data have not changed
          UPDATE brandsocialnetworks SET brandsocialnetworks.* = prec_data_new.*
            WHERE brandsocialnetworks.brndscl_id = lrec_data.brndscl_id
        ELSE
          LET lint_ret = -1
          LET lstr_msg = %"Record has been updated since edition started" 
        END IF
      OTHERWISE
    END CASE
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a row identified by the primary key in the "brandsocialnetworks" table
#+
#+ @param p_key - Primary Key
#+
#+ @returnType INTEGER
#+ @return     0|FAILURE, error message
PUBLIC FUNCTION brandsocialnetworks_delete_row(p_key)
  DEFINE
    p_key LIKE brandsocialnetworks.brndscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  TRY
    DELETE FROM brandsocialnetworks
      WHERE brandsocialnetworks.brndscl_id = p_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Select all rows in the "brandsocialnetworks" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like brandsocialnetworks.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetworks_fetch_all_rows(pstr_where, pstr_orderby, p_ret)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    p_ret DYNAMIC ARRAY OF RECORD LIKE brandsocialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brandsocialnetworks.*,
    lstr_sql STRING

  CALL p_ret.clear()
  LET lstr_sql = "SELECT brandsocialnetworks.* FROM brandsocialnetworks"," ",pstr_where, " ",pstr_orderby
  TRY
    DECLARE c_brandsocialnetworks_fetch_all_rows CURSOR FROM lstr_sql
    FOREACH c_brandsocialnetworks_fetch_all_rows
      INTO lrec_data.*
      LET p_ret[p_ret.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_brandsocialnetworks_fetch_all_rows
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the primary category of a brand
#+
#+ @param pint_brand_id brand id
#+
#+ @returnType INTEGER, STRING, RECORD
#+ @return     0|error, error message, categories.*
FUNCTION get_brand_primary_category(pint_brand_id LIKE brands.brnd_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE categories.*

  INITIALIZE lrec_data.* TO NULL
  TRY
    SELECT categories.*
      INTO lrec_data.*
    FROM brandcategories, categories
    WHERE brandcategories.brndcat_brand_id = pint_brand_id
      AND brandcategories.brndcat_category_id = categories.ctgr_id
      AND brandcategories.brndcat_isprimary = 1
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION

#+ Get the other categories of a brand
#+
#+ @param pint_brand_id brand id
#+ @param parec_list output list of categories
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_brand_primary_other_categories(pint_brand_id LIKE brands.brnd_id, parec_list DYNAMIC ARRAY OF RECORD LIKE categories.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data RECORD LIKE categories.*

  CALL parec_list.clear()
  LET lstr_sql = "SELECT categories.* FROM brandcategories, categories"
    ,SFMT(" WHERE brandcategories.brndcat_brand_id = %1", pint_brand_id)
    ," AND brandcategories.brndcat_category_id = categories.ctgr_id"
    ," AND brandcategories.brndcat_isprimary = 0"
    ," ORDER BY categories.ctgr_uiorder"
  TRY
    DECLARE c_get_brand_primary_other_categories CURSOR FROM lstr_sql
    FOREACH c_get_brand_primary_other_categories
      INTO lrec_data.*
      LET parec_list[parec_list.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_get_brand_primary_other_categories
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL parec_list.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the genders of a campaign
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_list output list of genders
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_campaign_genders(pint_campaign_id LIKE campaigns.cmp_id, parec_list DYNAMIC ARRAY OF RECORD LIKE genders.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data RECORD LIKE genders.*

  CALL parec_list.clear()
  LET lstr_sql = "SELECT genders.* FROM campaigngenders, genders"
    ,SFMT(" WHERE campaigngenders.cmpgen_campaign_id = %1", pint_campaign_id)
    ," AND campaigngenders.cmpgen_gender_id = genders.gnd_id"
    ," ORDER BY genders.gnd_uiorder"
  TRY
    DECLARE c_get_campaign_genders CURSOR FROM lstr_sql
    FOREACH c_get_campaign_genders
      INTO lrec_data.*
      LET parec_list[parec_list.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_get_campaign_genders
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL parec_list.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the categories of a campaign
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_list output list of categories
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_campaign_categories(pint_campaign_id LIKE campaigns.cmp_id, parec_list DYNAMIC ARRAY OF RECORD LIKE categories.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data RECORD LIKE categories.*

  CALL parec_list.clear()
  LET lstr_sql = "SELECT categories.* FROM campaigncategories, categories"
    ,SFMT(" WHERE campaigncategories.cmpcat_campaign_id = %1", pint_campaign_id)
    ," AND campaigncategories.cmpcat_category_id = categories.ctgr_id"
    ," ORDER BY categories.ctgr_uiorder"
  TRY
    DECLARE c_get_campaign_categories CURSOR FROM lstr_sql
    FOREACH c_get_campaign_categories
      INTO lrec_data.*
      LET parec_list[parec_list.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_get_campaign_categories
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL parec_list.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the campaignposttypes and posttypes of a campaign
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_campaignposttypes output list of campaignposttypes
#+ @param parec_posttypes output list of posttypes
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_campaign_campaignposttypes_and_posttypes(pint_campaign_id LIKE campaigns.cmp_id, parec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*, parec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_campaignposttypes RECORD LIKE campaignposttypes.*,
    lrec_posttypes RECORD LIKE posttypes.*

  CALL parec_campaignposttypes.clear()
  CALL parec_posttypes.clear()
  LET lstr_sql = "SELECT campaignposttypes.*, posttypes.* FROM campaignposttypes, posttypes"
    ,SFMT(" WHERE campaignposttypes.cmppst_campaign_id = %1", pint_campaign_id)
    ," AND campaignposttypes.cmppst_posttype_id = posttypes.pstt_id"
    ," ORDER BY posttypes.pstt_uiorder"
  TRY
    DECLARE c_get_campaign_campaignposttypes CURSOR FROM lstr_sql
    FOREACH c_get_campaign_campaignposttypes
      INTO lrec_campaignposttypes.*, lrec_posttypes.*
      LET parec_campaignposttypes[parec_campaignposttypes.getLength() + 1].* = lrec_campaignposttypes.*
      LET parec_posttypes[parec_posttypes.getLength() + 1].* = lrec_posttypes.*
    END FOREACH
    FREE c_get_campaign_campaignposttypes
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL parec_campaignposttypes.clear()
    CALL parec_posttypes.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the tags of a campaign
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_list output list of tags
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_campaign_tags(pint_campaign_id LIKE campaigns.cmp_id, pint_tag_type_id LIKE tagtypes.tagt_id, parec_list DYNAMIC ARRAY OF RECORD LIKE tags.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data RECORD LIKE tags.*

  CALL parec_list.clear()
  LET lstr_sql = "SELECT tags.* FROM campaigntags, tags"
    ,SFMT(" WHERE campaigntags.cmptg_campaign_id = %1", pint_campaign_id)
    ," AND campaigntags.cmptg_tag_id = tags.tag_id"
    ,SFMT(" AND tags.tag_type_id = %1", pint_tag_type_id)
    ," ORDER BY campaigntags.cmptg_uiorder"
  TRY
    DECLARE c_get_campaign_tags CURSOR FROM lstr_sql
    FOREACH c_get_campaign_tags
      INTO lrec_data.*
      LET parec_list[parec_list.getLength() + 1].* = lrec_data.*
    END FOREACH
    FREE c_get_campaign_tags
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL parec_list.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the number of awaited post per influencer for a campaign
#+
#+ @param pint_campaign_id campaign id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION get_campaign_number_of_awaited_post_per_influencer(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i, ret INTEGER,
    larec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*

  LET ret = 0
  --get number of awaited posts for the campaign
  CALL campaignposttypes_fetch_all_rows(SFMT("WHERE campaignposttypes.cmppst_campaign_id = %1", pint_campaign_id), NULL, larec_campaignposttypes)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg, ret END IF
  FOR i = 1 TO larec_campaignposttypes.getLength()
    LET ret = ret + larec_campaignposttypes[i].cmppst_quantity
  END FOR
  RETURN 0, NULL, ret
END FUNCTION

#+ Select a row identified by the primary key in the "messages" table
#+
#+ @param p_key Primary Key
#+ @param p_lock Indicate if a lock is used in order to prevent several userpostprices editing the same rows at the same time
#+
#+ @returnType INTEGER, STRING, LIKE messages.*
#+ @return     0|NOTFOUND|error, error message, RECORD LIKE messages.*
FUNCTION messages_select_row(p_key, p_lock)
  DEFINE
    p_key RECORD
      msg_id LIKE messages.msg_id,
      msg_lang LIKE messages.msg_lang
    END RECORD,
    p_lock BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE messages.*

  TRY
    IF p_lock THEN
      SELECT messages.*
        INTO lrec_data.*
      FROM messages
      WHERE messages.msg_id = p_key.msg_id
        AND messages.msg_lang = p_key.msg_lang
      FOR UPDATE
    ELSE
      SELECT messages.*
        INTO lrec_data.*
      FROM messages
      WHERE messages.msg_id = p_key.msg_id
        AND messages.msg_lang = p_key.msg_lang
    END IF
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = IIF(lint_ret==NOTFOUND, %"Record not found", NULL)
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_ret, lstr_msg, lrec_data.*
END FUNCTION
