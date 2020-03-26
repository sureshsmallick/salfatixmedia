IMPORT FGL createtables
IMPORT FGL insertdb

MAIN
    CONNECT TO "salfatixmedia"

	IF 1 == 0 THEN
		CALL insertInfluencersUTF8()
	ELSE
		CALL db_drop_constraints()
		CALL db_drop_tables()
		CALL db_create_tables()
		CALL db_add_constraints()
		CALL db_add_values()
	END IF
END MAIN

