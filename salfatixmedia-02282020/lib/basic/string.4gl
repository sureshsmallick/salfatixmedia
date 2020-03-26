IMPORT FGL core_cst
IMPORT FGL core_db

SCHEMA salfatixmedia

#+ Build a gender string from a list of genders.
#+ This string is used to be displayed inside a buttonedit field.
#+
#+ @param parec_data list of genders
#+
#+ @returnType STRING
#+ @return     gender string
FUNCTION serialize_genders(parec_data)
  DEFINE
    parec_data DYNAMIC ARRAY OF RECORD LIKE genders.*,
    lstr_ret STRING,
    i,s INTEGER

  LET s = parec_data.getLength()
  FOR i = 1 TO s
    IF i == 1 THEN
      LET lstr_ret = parec_data[i].gnd_name
    ELSE
      LET lstr_ret = lstr_ret, SFMT(", %1", parec_data[i].gnd_name)
    END IF
  END FOR
  RETURN lstr_ret
END FUNCTION

#+ Build a list of genders from a string
#+
#+ @param pstr_data string of genders
#+ @param parec_data output list of genders
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION deserialize_genders(pstr_data, parec_data)
  DEFINE
    pstr_data STRING,
    parec_data DYNAMIC ARRAY OF RECORD LIKE genders.*,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lrec_data RECORD LIKE genders.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL parec_data.clear()
  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, ",")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    CALL core_db.gender_select_row_by_name(lstr_tmp, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET parec_data[parec_data.getLength()+1].* = lrec_data.*
  END WHILE
  RETURN 0, NULL
END FUNCTION

#+ Build a category string from a list of categories.
#+ This string is used to be displayed inside a buttonedit field.
#+
#+ @param parec_data list of categories
#+
#+ @returnType STRING
#+ @return     category string
FUNCTION serialize_categories(parec_data)
  DEFINE
    parec_data DYNAMIC ARRAY OF RECORD LIKE categories.*,
    lstr_ret STRING,
    i,s INTEGER

  LET s = parec_data.getLength()
  FOR i = 1 TO s
    IF i == 1 THEN
      LET lstr_ret = parec_data[i].ctgr_name
    ELSE
      LET lstr_ret = lstr_ret, SFMT(", %1", parec_data[i].ctgr_name)
    END IF
  END FOR
  RETURN lstr_ret
END FUNCTION

#+ Build a list of categories from a string
#+
#+ @param pstr_data string of categories
#+ @param parec_data output list of categories
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION deserialize_categories(pstr_data, parec_data)
  DEFINE
    pstr_data STRING,
    parec_data DYNAMIC ARRAY OF RECORD LIKE categories.*,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lrec_data RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL parec_data.clear()
  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, ",")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    CALL core_db.category_select_row_by_name(lstr_tmp, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET parec_data[parec_data.getLength()+1].* = lrec_data.*
  END WHILE
  RETURN 0, NULL
END FUNCTION

#+ Build a string of category ids from a string
#+
#+ @param pstr_data string of categories
#+ @param parec_data output list of categories
#+
#+ @returnType STRING
#+ @return     list of ids from a string of categories
FUNCTION get_ids_from_categories(pstr_data)
  DEFINE
    pstr_data STRING,
    larec_data DYNAMIC ARRAY OF INTEGER,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lrec_data RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i,s INTEGER,
    ret STRING

  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, ",")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    CALL core_db.category_select_row_by_name(lstr_tmp, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    IF lint_ret <> 0 THEN
      RETURN NULL
    END IF
    LET s = s + 1
    LET larec_data[s] = lrec_data.ctgr_id
  END WHILE
  IF s == 0 THEN
    RETURN NULL
  END IF
  LET ret = SFMT("(%1",larec_data[1])
  FOR i = 2 TO s
    LET ret = SFMT("%1,%2",ret, larec_data[i])
  END FOR
  LET ret = SFMT("%1)",ret)
  RETURN ret
END FUNCTION

#+ Build a post type string from a list of posttypes.
#+ This string is used to be displayed inside a buttonedit field
#+
#+ @param parec_data list of post types
#+
#+ @returnType STRING
#+ @return     post type string
FUNCTION serialize_posttypes(parec_data)
  DEFINE
    parec_data DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    lstr_ret STRING,
    i,s INTEGER

  LET s = parec_data.getLength()
  FOR i = 1 TO s
    IF i == 1 THEN
      LET lstr_ret = parec_data[i].pstt_name
    ELSE
      LET lstr_ret = lstr_ret, SFMT(", %1", parec_data[i].pstt_name)
    END IF
  END FOR
  RETURN lstr_ret
END FUNCTION

#+ Build a list of posttypes from a string
#+
#+ @param pstr_data string of posttypes
#+ @param parec_data output list of posttypes
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION deserialize_posttypes(pstr_data, parec_data)
  DEFINE
    pstr_data STRING,
    parec_data DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lrec_data RECORD LIKE posttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL parec_data.clear()
  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, ",")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    CALL core_db.posttype_select_row_by_name(lstr_tmp, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET parec_data[parec_data.getLength()+1].* = lrec_data.*
  END WHILE
  RETURN 0, NULL
END FUNCTION

#+ Build the a tags string from a list of tags.
#+
#+ @param parec_data list of tags
#+ @param pint_tagtype_id tag type
#+
#+ @returnType STRING
#+ @return     tags string
FUNCTION serialize_tags(parec_data, pint_tagtype_id)
  DEFINE
    parec_data DYNAMIC ARRAY OF RECORD LIKE tags.*,
    pint_tagtype_id LIKE tagtypes.tagt_id,
    lstr_ret STRING,
    i,s INTEGER

  LET s = parec_data.getLength()
  FOR i = 1 TO s
    IF parec_data[i].tag_type_id == pint_tagtype_id THEN
      IF i == 1 THEN
        LET lstr_ret = parec_data[i].tag_name
      ELSE
        LET lstr_ret = lstr_ret, SFMT(" %1", parec_data[i].tag_name)
      END IF
    END IF
  END FOR
  RETURN lstr_ret
END FUNCTION

#+ Build a list of tags from a string
#+
#+ @param pstr_data string of tags
#+ @param parec_data output list of tags
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION deserialize_tags(pstr_data, parec_data)
  DEFINE
    pstr_data STRING,
    parec_data DYNAMIC ARRAY OF RECORD LIKE tags.*,
    lint_tagtype_id LIKE tagtypes.tagt_id,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lstr_tagtype STRING,
    lrec_data RECORD LIKE tags.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL parec_data.clear()
  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, " ")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    LET lstr_tagtype = lstr_tmp.getCharAt(1)
    CASE lstr_tagtype
      WHEN "#"
        LET lint_tagtype_id = C_TAGTYPE_HASHTAG
      WHEN "@"
        LET lint_tagtype_id = C_TAGTYPE_USERTAG
      OTHERWISE
        RETURN -1, %"Tag type missing"
    END CASE
    CALL core_db.tags_select_row_by_name_and_type(lstr_tmp, lint_tagtype_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_data.*
    CASE lint_ret
      WHEN 0
      WHEN NOTFOUND
        INITIALIZE lrec_data.* TO NULL
        LET lrec_data.tag_id = 0
        LET lrec_data.tag_name = lstr_tmp
        LET lrec_data.tag_type_id = lint_tagtype_id
      OTHERWISE
        RETURN lint_ret, lstr_msg
    END CASE
    LET parec_data[parec_data.getLength()+1].* = lrec_data.*
  END WHILE
  RETURN 0, NULL
END FUNCTION

#+ Check if the given tag string has the valid format
#+
#+ @param pstr_data string of tags delimited by ' '
#+ @param pint_tagtype_id tag type
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION validate_tags_format(pstr_data, pint_tagtype_id)
  DEFINE
    pstr_data STRING,
    pint_tagtype_id LIKE tagtypes.tagt_id,
    lstr_tmp STRING,
    lstr_tok base.StringTokenizer,
    lstr_tagtype STRING,
    l_dict DICTIONARY OF INTEGER

  LET pstr_data = pstr_data.trim()
  LET lstr_tok = base.StringTokenizer.create(pstr_data, " ")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    LET lstr_tagtype = lstr_tmp.getCharAt(1)
    IF lstr_tagtype <> pint_tagtype_id THEN
      RETURN -1, %"Tag type missing"
    END IF
    IF l_dict.contains(lstr_tmp) THEN
      RETURN -1, %"Duplicated tag"
    ELSE
      LET l_dict[lstr_tmp] = 1
    END IF
  END WHILE
  RETURN 0, NULL
END FUNCTION

#+ Get a country phone prefix
#+
#+ @param pint_country_id country id
#+
#+ @returnType STRING
#+ @return     phone number prefix
FUNCTION get_phonenumberprefix(pint_country_id)
  DEFINE
    pint_country_id LIKE countries.cntr_id,
    lstr_phonenumberprefix STRING

  INITIALIZE lstr_phonenumberprefix TO NULL
  IF pint_country_id IS NOT NULL AND pint_country_id > 0 THEN
    LET lstr_phonenumberprefix = core_db.country_get_phoneprefix(pint_country_id)
  END IF
  IF lstr_phonenumberprefix.getLength() > 0 THEN
    LET lstr_phonenumberprefix = "+" || lstr_phonenumberprefix
  END IF
  RETURN lstr_phonenumberprefix
END FUNCTION

#+ Build phone number string from their country and phone
#+
#+ @param pint_country_id country id
#+ @param pstr_phonenumber phone number string
#+
#+ @returnType STRING
#+ @return     phone number
FUNCTION build_phonenumber(pint_country_id, pstr_phonenumber)
  DEFINE
    pint_country_id LIKE countries.cntr_id,
    pstr_phonenumber STRING

  RETURN SFMT("%1%2",get_phonenumberprefix(pint_country_id), pstr_phonenumber)
END FUNCTION

#+ Append a string to a new one using a separator
#+
#+ @param pstr_string original string
#+ @param pstr_to_add string to append
#+
#+ @returnType STRING
#+ @return     concatenated string with a separator
FUNCTION concat(pstr_string STRING, pstr_to_add STRING)
  RETURN IIF(pstr_string.getLength()==0, pstr_to_add, SFMT("%1, %2",pstr_string, pstr_to_add))
END FUNCTION

#+ Append a string to a new one using a given separator
#+
#+ @param pstr_string original string
#+ @param pstr_to_add string to append
#+ @param pstr_delim string delimiter
#+
#+ @returnType STRING
#+ @return     concatenated string with a separator
FUNCTION concat_with_delim(pstr_string STRING, pstr_to_add STRING, pstr_delim STRING)
  RETURN IIF(pstr_string.getLength()==0, pstr_to_add, SFMT("%1%3%2",pstr_string, pstr_to_add, pstr_delim))
END FUNCTION

#+ Get the post time from an hour
#+
#+ @param pint_hour hour
#+
FUNCTION get_posttime_string(pint_hour INTEGER)
  IF pint_hour == C_POSTTIME_ANYTIME THEN
    RETURN %"Any time"
  END IF
  RETURN SFMT("%1h", pint_hour)
END FUNCTION

#+ Convert a string containing a date into a string with no special characters
#+
#+ @param pstr_date date provided as a string
#+
#+ @returnType STRING
#+ @return     a string containing a date into a string with no special characters, NULL in case of error
FUNCTION get_name_from_date(pstr_date)
  DEFINE
    pstr_date STRING,
    lbuf base.StringBuffer

  IF pstr_date IS NULL THEN
    RETURN NULL
  END IF
  LET lbuf = base.StringBuffer.create()
  CALL lbuf.append(pstr_date.trim())
  CALL lbuf.replace("-","",0)
  CALL lbuf.replace(":","",0)
  CALL lbuf.replace(".","",0)
  CALL lbuf.replace(" ","_",0)
  RETURN lbuf.toString()
END FUNCTION

#+ Get a report name
#+
#+ @param s main description
#+ @param ext extension like ".xml" ".png"
#+
#+ @returnType STRING
#+ @return     a string containing a date into a string with no special characters, NULL in case of error
FUNCTION get_report_name(s STRING, ext STRING)
  RETURN SFMT("%1_%2_%3%4",s,get_name_from_date(CURRENT),FGL_GETPID(), ext) 
END FUNCTION

#+ Remove trailing spaces from the given parameter
#+
#+ @param s parameter (already converted to string)
#+
#+ @returnType STRING
#+ @return     parameter trimed
FUNCTION trim(s STRING)
  RETURN s.trim()
END FUNCTION

#+ Count occurrences in a string from a given parameter
#+
#+ @param s string to parse
#+ @param t token to count
#+
#+ @returnType INTEGER
#+ @return     number of occurrences
FUNCTION countTokens(s String, t String)
  DEFINE
    st base.StringTokenizer

  LET st = base.StringTokenizer.create(s,t)
  RETURN st.countTokens()
END FUNCTION