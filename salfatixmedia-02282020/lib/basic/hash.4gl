IMPORT security

#+ Compute the hash for a given string
#+
#+ @param pstr_string string to hash
#+ @param pstr_algo hash algorithm (SHA1, SHA512, SHA384, SHA256, SHA224, MD5, BCRYPT)
#+ @param pstr_do_base64 TRUE for base64 output, FALSE for hexadecimal output
#+
#+ @returnType STRING
#+ @return     hash value for a given string
FUNCTION compute_hash(pstr_string, pstr_algo, pstr_do_base64)
  DEFINE
    pstr_string STRING,
    pstr_algo STRING,
    pstr_do_base64 BOOLEAN,
    dgst security.Digest,
    pstr_ret STRING
  TRY
    IF pstr_algo == "BCRYPT" THEN
      CALL security.BCrypt.HashPassword(pstr_string, NULL) RETURNING pstr_ret
    ELSE
      LET dgst = security.Digest.CreateDigest(pstr_algo)
      CALL dgst.AddStringData(pstr_string)
      LET pstr_ret = IIF(pstr_do_base64, dgst.DoBase64Digest(), dgst.DoHexBinaryDigest())
    END IF
  CATCH
    DISPLAY %"ERROR : ", STATUS, " - ", SQLCA.SQLERRM
    EXIT PROGRAM(-1)
  END TRY
  RETURN pstr_ret
END FUNCTION

#+ Verify if the given hash matches the computed hash for a given string
#+
#+ @param pstr_hash hash to verify
#+ @param pstr_string string to hash
#+ @param pstr_algo hash algorithm (SHA1, SHA512, SHA384, SHA256, SHA224, MD5, BCRYPT)
#+ @param pstr_do_base64 TRUE for base64 output, FALSE for hexadecimal output
#+
#+ @returnType BOOLEAN
#+ @return     TRUE when the given hash matches the computed hash, FALSE otherwise
FUNCTION verify_hash(pstr_hash, pstr_string, pstr_algo, pstr_do_base64)
  DEFINE
    pstr_hash STRING,
    pstr_string STRING,
    pstr_algo STRING,
    pstr_do_base64 BOOLEAN,
    lstr_computed_hash STRING

  IF pstr_algo == "BCRYPT" THEN
    RETURN security.BCrypt.CheckPassword(pstr_string, pstr_hash)
  END IF
  LET lstr_computed_hash = compute_hash(pstr_string, pstr_algo, pstr_do_base64)
  RETURN pstr_hash.equals(lstr_computed_hash)
END FUNCTION