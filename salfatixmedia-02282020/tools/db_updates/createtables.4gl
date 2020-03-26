#+ Create all tables in database.
FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE accountstatus (
        accst_id INTEGER NOT NULL,
        accst_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE backofficeusers (
        bousr_id SERIAL NOT NULL,
        bousr_password VARCHAR(255) NOT NULL,
        bousr_pic_id INTEGER NOT NULL,
        bousr_gender_id INTEGER,
        bousr_firstname VARCHAR(128),
        bousr_lastname VARCHAR(128),
        bousr_email VARCHAR(128) NOT NULL,
        bousr_email_style CHAR(1),
        bousr_country_id INTEGER NOT NULL,
        bousr_state_id INTEGER,
        bousr_city_id INTEGER,
        bousr_address_number VARCHAR(16),
        bousr_address_street VARCHAR(128),
        bousr_address_zipcode VARCHAR(128),
        bousr_address_town VARCHAR(128),
        bousr_address_more VARCHAR(128),
        bousr_mobile_phone BIGINT,
        bousr_isadmin SMALLINT NOT NULL,
        bousr_usrrole_id INTEGER,
        bousr_accountstatus_id INTEGER NOT NULL,
        bousr_creationdate DATETIME YEAR TO SECOND NOT NULL,
        bousr_deletiondate DATETIME YEAR TO SECOND,
        bousr_stopdate DATETIME YEAR TO SECOND,
        bousr_lastupdatedate DATETIME YEAR TO SECOND,
        bousr_lastlogindate DATETIME YEAR TO SECOND)"
    EXECUTE IMMEDIATE "CREATE TABLE booperations (
        boop_id INTEGER NOT NULL,
        boop_name VARCHAR(64) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE boroleperations (
        borlop_borole_id INTEGER NOT NULL,
        borlop_booperation_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE boroles (
        borl_id SERIAL NOT NULL,
        borl_name VARCHAR(64) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE brandcategories (
        brndcat_brand_id INTEGER NOT NULL,
        brndcat_category_id INTEGER NOT NULL,
        brndcat_isprimary SMALLINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE brands (
        brnd_id SERIAL NOT NULL,
        brnd_pic_id INTEGER NOT NULL,
        brnd_name VARCHAR(128) NOT NULL,
        brnd_website VARCHAR(255),
        brnd_country_id INTEGER NOT NULL,
        brnd_state_id INTEGER,
        brnd_city_id INTEGER,
        brnd_address_number VARCHAR(16),
        brnd_address_street VARCHAR(128),
        brnd_address_zipcode VARCHAR(128),
        brnd_address_town VARCHAR(128),
        brnd_address_more VARCHAR(128),
        brnd_currency_id INTEGER NOT NULL,
        brnd_gender_id INTEGER,
        brnd_firstname VARCHAR(128),
        brnd_lastname VARCHAR(128),
        brnd_contact_rank VARCHAR(128),
        brnd_email VARCHAR(128) NOT NULL,
        brnd_email_style CHAR(1),
        brnd_password VARCHAR(255) NOT NULL,
        brnd_mobile_phonenumber BIGINT,
        brnd_accountstatus_id INTEGER NOT NULL,
        brnd_createdby_id INTEGER NOT NULL,
        brnd_creationdate DATETIME YEAR TO SECOND NOT NULL,
        brnd_deletiondate DATETIME YEAR TO SECOND,
        brnd_validationdate DATETIME YEAR TO SECOND,
        brnd_canceldate DATETIME YEAR TO SECOND,
        brnd_suspendeddate DATETIME YEAR TO SECOND,
        brnd_stopdate DATETIME YEAR TO SECOND,
        brnd_emailvalidationdate DATETIME YEAR TO SECOND,
        brnd_lastupdatedate DATETIME YEAR TO SECOND,
        brnd_lastlogindate DATETIME YEAR TO SECOND)"
    EXECUTE IMMEDIATE "CREATE TABLE brandsocialnetworks (
        brndscl_id SERIAL NOT NULL,
        brndscl_brand_id INTEGER NOT NULL,
        brndscl_socialnetwork_id INTEGER NOT NULL,
        brndscl_accountname VARCHAR(255) NOT NULL,
        brndscl_comment VARCHAR(255))"
    EXECUTE IMMEDIATE "CREATE TABLE campaigncategories (
        cmpcat_campaign_id INTEGER NOT NULL,
        cmpcat_category_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaigncities (
        cmpcts_id SERIAL NOT NULL,
        cmpcts_campaignstate_id INTEGER NOT NULL,
        cmpcts_city_id INTEGER)"
    EXECUTE IMMEDIATE "CREATE TABLE campaigncountries (
        cmpcntr_id SERIAL NOT NULL,
        cmpcntr_campaign_id INTEGER NOT NULL,
        cmpcntr_country_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaigngenders (
        cmpgen_campaign_id INTEGER NOT NULL,
        cmpgen_gender_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignphotos (
        cmpph_campaign_id INTEGER NOT NULL,
        cmpph_pic_id INTEGER NOT NULL,
        cmpph_uiorder INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignposts (
        cmppost_id SERIAL NOT NULL,
        cmppost_campaign_id INTEGER NOT NULL,
        cmppost_usr_id INTEGER NOT NULL,
        cmppost_posttype_id INTEGER NOT NULL,
        cmppost_url VARCHAR(255),
        cmppost_ispublic SMALLINT,
        cmppost_status_id INTEGER NOT NULL,
        cmppost_screenshot_post VARCHAR(255),
        cmppost_screenshot_stat VARCHAR(255),
        cmppost_creationdate DATETIME YEAR TO SECOND NOT NULL,
        cmppost_youtube_viewcount INTEGER,
        cmppost_youtube_likecount INTEGER,
        cmppost_youtube_dislikecount INTEGER,
        cmppost_youtube_favoritecount INTEGER,
        cmppost_youtube_commentcount INTEGER,
        cmppost_ig_likes INTEGER,
        cmppost_ig_comments INTEGER,
        cmppost_ig_saved INTEGER,
        cmppost_ig_profilevisits INTEGER,
        cmppost_ig_follows INTEGER,
        cmppost_ig_websiteclicks INTEGER,
        cmppost_ig_discovery DECIMAL(5,2),
        cmppost_ig_reach INTEGER,
        cmppost_ig_impressions INTEGER,
        cmppost_instastory_impressions INTEGER,
        cmppost_instastory_reach INTEGER,
        cmppost_instastory_tapsforward INTEGER,
        cmppost_instastory_tapsback INTEGER,
        cmppost_instastory_replies INTEGER,
        cmppost_instastory_swipeaway INTEGER,
        cmppost_instastory_exists INTEGER,
        cmppost_isacceptedbysalfatix SMALLINT,
        cmppost_isacceptedbybrand SMALLINT,
        cmppost_filename VARCHAR(255),
        cmppost_postno SMALLINT,
        cmppost_uiorder SMALLINT)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignpostshist (
        cmpposth_id SERIAL NOT NULL,
        cmpposth_campaignpost_id INTEGER NOT NULL,
        cmpposth_status_id INTEGER NOT NULL,
        cmpposth_statusdate DATETIME YEAR TO SECOND NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignpoststatus (
        cmppstst_id INTEGER NOT NULL,
        cmppstst_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignposttypes (
        cmppst_campaign_id INTEGER NOT NULL,
        cmppst_posttype_id INTEGER NOT NULL,
        cmppst_quantity INTEGER NOT NULL,
        cmppst_tovalidate SMALLINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaigns (
        cmp_id SERIAL NOT NULL,
        cmp_brand_id INTEGER NOT NULL,
        cmp_pic_id INTEGER NOT NULL,
        cmp_title VARCHAR(64),
        cmp_overview VARCHAR(255),
        cmp_url VARCHAR(255),
        cmp_isproductneeded SMALLINT NOT NULL,
        cmp_prd_description VARCHAR(255),
        cmp_prd_value DECIMAL(10,2),
        cmp_issharedonfacebook SMALLINT NOT NULL,
        cmp_sharedfacebooklink VARCHAR(255),
        cmp_post_guidelines VARCHAR(128),
        cmp_captionrequirements VARCHAR(255),
        cmp_post_startdate DATE,
        cmp_post_enddate DATE,
        cmp_post_time_starttime INTEGER,
        cmp_post_time_endtime INTEGER,
        cmp_postduration_id INTEGER,
        cmp_totalbudget DECIMAL(10,2),
        cmp_deposit DECIMAL(10,2),
        cmp_depositpercent DECIMAL(6,2),
        cmp_currency_id INTEGER,
        cmp_wantedusers INTEGER,
        cmp_campaignstatus_id INTEGER NOT NULL,
        cmp_createdby_id INTEGER NOT NULL,
        cmp_creationdate DATETIME YEAR TO SECOND NOT NULL,
        cmp_publisheddate DATE,
        cmp_selectionstartdate DATE,
        cmp_selectionenddate DATE,
        cmp_selectioncomment VARCHAR(128),
        cmp_actionstartdate DATETIME YEAR TO SECOND,
        cmp_actionenddate DATETIME YEAR TO SECOND,
        cmp_enddate DATETIME YEAR TO SECOND,
        cmp_lastupdatedate DATETIME YEAR TO SECOND)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignshist (
        cmph_id SERIAL NOT NULL,
        cmph_campaign_id INTEGER NOT NULL,
        cmph_campaignstatus_id INTEGER NOT NULL,
        cmph_date DATETIME YEAR TO SECOND NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignstates (
        cmpstt_id SERIAL NOT NULL,
        cmpstt_campaigncountry_id INTEGER NOT NULL,
        cmpstt_state_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignstatus (
        cmpst_id INTEGER NOT NULL,
        cmpst_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaigntags (
        cmptg_campaign_id INTEGER NOT NULL,
        cmptg_tag_id INTEGER NOT NULL,
        cmptg_uiorder INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE campaignuserlist (
        cmpusrl_id SERIAL NOT NULL,
        cmpusrl_campaign_id INTEGER NOT NULL,
        cmpusrl_user_id INTEGER NOT NULL,
        cmpusrl_visibilitydate DATE NOT NULL,
        cmpusrl_previewuser SMALLINT NOT NULL,
        cmpusrl_wantedbybrand SMALLINT NOT NULL,
        cmpusrl_selectionstartdate DATE NOT NULL,
        cmpusrl_selectionenddate DATE NOT NULL,
        cmpusrl_selectioncomment VARCHAR(128),
        cmpusrl_tonotify SMALLINT NOT NULL,
        cmpusrl_notificationdate DATETIME YEAR TO SECOND,
        cmpusrl_isacceptbyuser SMALLINT,
        cmpusrl_useranswerdate DATETIME YEAR TO SECOND,
        cmpusrl_usertotalprice DECIMAL(10,2) NOT NULL,
        cmpusrl_salfatixtotalprice DECIMAL(10,2) NOT NULL,
        cmpusrl_userwantedprice DECIMAL(10,2),
        cmpusrl_uiorder INTEGER,
        cmpusrl_isacceptedbysalfatix SMALLINT,
        cmpusrl_isacceptedbybrand SMALLINT,
        cmpusrl_commentforbrand VARCHAR(128),
        cmpusrl_usergotproduct SMALLINT,
        cmpusrl_isuserpaid SMALLINT,
        cmpusrl_userpaid DECIMAL(10,2))"
    EXECUTE IMMEDIATE "CREATE TABLE campaignuserprices (
        cmpusrp_campaign_id INTEGER NOT NULL,
        cmpusrp_usr_id INTEGER NOT NULL,
        cmpusrp_posttype_id INTEGER NOT NULL,
        cmpusrp_price DECIMAL(10,2),
        cmpusrp_freeofcharge SMALLINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE categories (
        ctgr_id SERIAL NOT NULL,
        ctgr_name VARCHAR(32) NOT NULL,
        ctgr_uiorder INTEGER NOT NULL,
        ctgr_parent_id INTEGER)"
    EXECUTE IMMEDIATE "CREATE TABLE cities (
        cts_id INTEGER NOT NULL,
        cts_name VARCHAR(60) NOT NULL,
        cts_state_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE countries (
        cntr_id INTEGER NOT NULL,
        cntr_sortname VARCHAR(4) NOT NULL,
        cntr_name VARCHAR(64) NOT NULL,
        cntr_phonecode INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE createdby (
        crcb_id INTEGER NOT NULL,
        crcb_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE currencies (
        crr_id INTEGER NOT NULL,
        crr_name VARCHAR(32) NOT NULL,
        crr_symbol VARCHAR(8))"
    EXECUTE IMMEDIATE "CREATE TABLE genders (
        gnd_id INTEGER NOT NULL,
        gnd_name VARCHAR(16) NOT NULL,
        gnd_uiorder INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE grouptags (
        gtag_id SERIAL NOT NULL,
        gtag_name VARCHAR(128) NOT NULL,
        gtag_creationdate DATETIME YEAR TO SECOND NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE grouptagslist (
        gtagl_grouptag_id INTEGER NOT NULL,
        gtagl_tag_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE messages (
        msg_id INTEGER NOT NULL,
        msg_lang VARCHAR(8) NOT NULL,
        msg_texttitle VARCHAR(255),
        msg_textcontent LVARCHAR(4096),
        msg_htmltitle VARCHAR(255),
        msg_htmlcontent LVARCHAR(4096))"
    EXECUTE IMMEDIATE "CREATE TABLE notificationtokens (
        ntt_id SERIAL NOT NULL,
        ntt_usr_id INTEGER NOT NULL,
        ntt_unique_id VARCHAR(200) NOT NULL,
        ntt_device_type VARCHAR(10) NOT NULL,
        ntt_meter INTEGER,
        ntt_token VARCHAR(200) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE params (
        par_id SERIAL NOT NULL,
        par_typ INTEGER NOT NULL,
        par_min DECIMAL(10,2) NOT NULL,
        par_max DECIMAL(10,2) NOT NULL,
        par_des VARCHAR(200) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE pics (
        pic_id SERIAL NOT NULL,
        pic_value BYTE NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE postdurations (
        pstdr_id INTEGER NOT NULL,
        pstdr_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE posttypes (
        pstt_id INTEGER NOT NULL,
        pstt_name VARCHAR(32) NOT NULL,
        pstt_uiorder INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE proposalstatus (
        prp_id INTEGER NOT NULL,
        prp_name VARCHAR(32) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE socialnetworks (
        scl_id INTEGER NOT NULL,
        scl_name VARCHAR(64) NOT NULL,
        scl_uiorder INTEGER NOT NULL,
        scl_img VARCHAR(32) NOT NULL,
        scl_url VARCHAR(255))"
    EXECUTE IMMEDIATE "CREATE TABLE states (
        stt_id INTEGER NOT NULL,
        stt_name VARCHAR(60) NOT NULL,
        stt_country_id INTEGER NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE tags (
        tag_id SERIAL NOT NULL,
        tag_name VARCHAR(128) NOT NULL,
        tag_type_id INTEGER)"
    EXECUTE IMMEDIATE "CREATE TABLE tagtypes (
        tagt_id INTEGER NOT NULL,
        tagt_name VARCHAR(16) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE usermetrics (
        usrmtc_id SERIAL NOT NULL,
        usrmtc_usr_id INTEGER,
        usrmtc_instagram_userid BIGINT,
        usrmtc_instagram_username VARCHAR(128),
        usrmtc_geomedia_count INTEGER,
        usrmtc_media_count INTEGER,
        usrmtc_follows_count INTEGER,
        usrmtc_followers_count INTEGER,
        usrmtc_comments_count INTEGER,
        usrmtc_likes_count INTEGER,
        usrmtc_usertags_count INTEGER,
        usrmtc_reach INTEGER,
        usrmtc_bdate DATETIME YEAR TO SECOND NOT NULL,
        usrmtc_edate DATETIME YEAR TO SECOND NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE userpostprices (
        usrpp_usr_id INTEGER NOT NULL,
        usrpp_posttype_id INTEGER NOT NULL,
        usrpp_minprice DECIMAL(10,2) NOT NULL,
        usrpp_maxprice DECIMAL(10,2) NOT NULL,
        usrpp_freeofcharge SMALLINT NOT NULL,
        usrpp_salfatixminprice DECIMAL(10,2),
        usrpp_salfatixmaxprice DECIMAL(10,2),
        usrpp_salfatixfreeofcharge SMALLINT NOT NULL,
        usrpp_isvalidatedbysalfatix SMALLINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE users (
        usr_id SERIAL NOT NULL,
        usr_gender_id INTEGER,
        usr_firstname VARCHAR(128),
        usr_lastname VARCHAR(128),
        usr_birthday DATE,
        usr_email VARCHAR(128) NOT NULL,
        usr_password VARCHAR(255) NOT NULL,
        usr_country_id INTEGER NOT NULL,
        usr_state_id INTEGER,
        usr_city_id INTEGER,
        usr_address_number VARCHAR(16),
        usr_address_street VARCHAR(128),
        usr_address_zipcode VARCHAR(128),
        usr_address_town VARCHAR(128),
        usr_address_more VARCHAR(128),
        usr_mobile_phone BIGINT,
        usr_instagram_userid BIGINT,
        usr_instagram_username VARCHAR(128) NOT NULL,
        usr_instagram_fullname VARCHAR(128),
        usr_instagram_profilepicture VARCHAR(255),
        usr_instagram_biography VARCHAR(255),
        usr_instagram_website VARCHAR(255),
        usr_instagram_is_private SMALLINT,
        usr_instagram_is_verified SMALLINT,
        usr_instagram_is_business SMALLINT,
        usr_bank_name VARCHAR(128),
        usr_bank_iban VARCHAR(64),
        usr_bank_swift VARCHAR(64),
        usr_paypal VARCHAR(128),
        usr_mobile_notifications SMALLINT,
        usr_notif_style CHAR(1),
        usr_email_notifications SMALLINT,
        usr_email_style CHAR(1),
        usr_currency_id INTEGER,
        usr_accountstatus_id INTEGER NOT NULL,
        usr_createdby_id INTEGER NOT NULL,
        usr_creationdate DATETIME YEAR TO SECOND NOT NULL,
        usr_deletiondate DATETIME YEAR TO SECOND,
        usr_validationdate DATETIME YEAR TO SECOND,
        usr_canceldate DATETIME YEAR TO SECOND,
        usr_suspendeddate DATETIME YEAR TO SECOND,
        usr_stopdate DATETIME YEAR TO SECOND,
        usr_emailvalidationdate DATETIME YEAR TO SECOND,
        usr_lastupdatedate DATETIME YEAR TO SECOND,
        usr_lastlogindate DATETIME YEAR TO SECOND,
        usr_instagram_token VARCHAR(255))"
    EXECUTE IMMEDIATE "CREATE TABLE usersocialnetworks (
        usrscl_id SERIAL NOT NULL,
        usrscl_usr_id INTEGER NOT NULL,
        usrscl_socialnetwork_id INTEGER NOT NULL,
        usrscl_accountname VARCHAR(255) NOT NULL,
        usrscl_comment VARCHAR(255))"

END FUNCTION

#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "DROP TABLE accountstatus"
    EXECUTE IMMEDIATE "DROP TABLE backofficeusers"
    EXECUTE IMMEDIATE "DROP TABLE booperations"
    EXECUTE IMMEDIATE "DROP TABLE boroleperations"
    EXECUTE IMMEDIATE "DROP TABLE boroles"
    EXECUTE IMMEDIATE "DROP TABLE brandcategories"
    EXECUTE IMMEDIATE "DROP TABLE brands"
    EXECUTE IMMEDIATE "DROP TABLE brandsocialnetworks"
    EXECUTE IMMEDIATE "DROP TABLE campaigncategories"
    EXECUTE IMMEDIATE "DROP TABLE campaigncities"
    EXECUTE IMMEDIATE "DROP TABLE campaigncountries"
    EXECUTE IMMEDIATE "DROP TABLE campaigngenders"
    EXECUTE IMMEDIATE "DROP TABLE campaignphotos"
    EXECUTE IMMEDIATE "DROP TABLE campaignposts"
    EXECUTE IMMEDIATE "DROP TABLE campaignpostshist"
    EXECUTE IMMEDIATE "DROP TABLE campaignpoststatus"
    EXECUTE IMMEDIATE "DROP TABLE campaignposttypes"
    EXECUTE IMMEDIATE "DROP TABLE campaigns"
    EXECUTE IMMEDIATE "DROP TABLE campaignshist"
    EXECUTE IMMEDIATE "DROP TABLE campaignstates"
    EXECUTE IMMEDIATE "DROP TABLE campaignstatus"
    EXECUTE IMMEDIATE "DROP TABLE campaigntags"
    EXECUTE IMMEDIATE "DROP TABLE campaignuserlist"
    EXECUTE IMMEDIATE "DROP TABLE campaignuserprices"
    EXECUTE IMMEDIATE "DROP TABLE categories"
    EXECUTE IMMEDIATE "DROP TABLE cities"
    EXECUTE IMMEDIATE "DROP TABLE countries"
    EXECUTE IMMEDIATE "DROP TABLE createdby"
    EXECUTE IMMEDIATE "DROP TABLE currencies"
    EXECUTE IMMEDIATE "DROP TABLE genders"
    EXECUTE IMMEDIATE "DROP TABLE grouptags"
    EXECUTE IMMEDIATE "DROP TABLE grouptagslist"
    EXECUTE IMMEDIATE "DROP TABLE messages"
    EXECUTE IMMEDIATE "DROP TABLE notificationtokens"
    EXECUTE IMMEDIATE "DROP TABLE params"
    EXECUTE IMMEDIATE "DROP TABLE pics"
    EXECUTE IMMEDIATE "DROP TABLE postdurations"
    EXECUTE IMMEDIATE "DROP TABLE posttypes"
    EXECUTE IMMEDIATE "DROP TABLE proposalstatus"
    EXECUTE IMMEDIATE "DROP TABLE socialnetworks"
    EXECUTE IMMEDIATE "DROP TABLE states"
    EXECUTE IMMEDIATE "DROP TABLE tags"
    EXECUTE IMMEDIATE "DROP TABLE tagtypes"
    EXECUTE IMMEDIATE "DROP TABLE usermetrics"
    EXECUTE IMMEDIATE "DROP TABLE userpostprices"
    EXECUTE IMMEDIATE "DROP TABLE users"
    EXECUTE IMMEDIATE "DROP TABLE usersocialnetworks"

END FUNCTION

#+ Add constraints for all tables.
FUNCTION db_add_constraints()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "ALTER TABLE accountstatus ADD CONSTRAINT
        PRIMARY KEY (accst_id)
        CONSTRAINT u226_660"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT
        PRIMARY KEY (bousr_id)
        CONSTRAINT u258_737"
    EXECUTE IMMEDIATE "ALTER TABLE booperations ADD CONSTRAINT
        PRIMARY KEY (boop_id)
        CONSTRAINT u249_748"
    EXECUTE IMMEDIATE "ALTER TABLE boroleperations ADD CONSTRAINT
        PRIMARY KEY (borlop_borole_id, borlop_booperation_id)
        CONSTRAINT u250_751"
    EXECUTE IMMEDIATE "ALTER TABLE boroles ADD CONSTRAINT
        PRIMARY KEY (borl_id)
        CONSTRAINT u248_745"
    EXECUTE IMMEDIATE "ALTER TABLE brandcategories ADD CONSTRAINT
        PRIMARY KEY (brndcat_brand_id, brndcat_category_id)
        CONSTRAINT u228_666"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT
        PRIMARY KEY (brnd_id)
        CONSTRAINT u260_646"
    EXECUTE IMMEDIATE "ALTER TABLE brandsocialnetworks ADD CONSTRAINT
        PRIMARY KEY (brndscl_id)
        CONSTRAINT u291_1022"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncategories ADD CONSTRAINT
        PRIMARY KEY (cmpcat_campaign_id, cmpcat_category_id)
        CONSTRAINT u231_678"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncities ADD CONSTRAINT
        PRIMARY KEY (cmpcts_id)
        CONSTRAINT u269_868"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncountries ADD CONSTRAINT
        PRIMARY KEY (cmpcntr_id)
        CONSTRAINT u267_860"
    EXECUTE IMMEDIATE "ALTER TABLE campaigngenders ADD CONSTRAINT
        PRIMARY KEY (cmpgen_campaign_id, cmpgen_gender_id)
        CONSTRAINT u290_1016"
    EXECUTE IMMEDIATE "ALTER TABLE campaignphotos ADD CONSTRAINT
        PRIMARY KEY (cmpph_campaign_id, cmpph_pic_id)
        CONSTRAINT u257_816"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts ADD CONSTRAINT
        PRIMARY KEY (cmppost_id)
        CONSTRAINT u288_993"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpostshist ADD CONSTRAINT
        PRIMARY KEY (cmpposth_id)
        CONSTRAINT u289_1006"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpoststatus ADD CONSTRAINT
        PRIMARY KEY (cmppstst_id)
        CONSTRAINT u286_981"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposttypes ADD CONSTRAINT
        PRIMARY KEY (cmppst_campaign_id, cmppst_posttype_id)
        CONSTRAINT u233_684"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT
        PRIMARY KEY (cmp_id)
        CONSTRAINT u276_669"
    EXECUTE IMMEDIATE "ALTER TABLE campaignshist ADD CONSTRAINT
        PRIMARY KEY (cmph_id)
        CONSTRAINT u292_1030"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstates ADD CONSTRAINT
        PRIMARY KEY (cmpstt_id)
        CONSTRAINT u268_864"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstatus ADD CONSTRAINT
        PRIMARY KEY (cmpst_id)
        CONSTRAINT u227_663"
    EXECUTE IMMEDIATE "ALTER TABLE campaigntags ADD CONSTRAINT
        PRIMARY KEY (cmptg_campaign_id, cmptg_tag_id)
        CONSTRAINT u235_692"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserlist ADD CONSTRAINT
        PRIMARY KEY (cmpusrl_id)
        CONSTRAINT u273_911"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices ADD CONSTRAINT
        PRIMARY KEY (cmpusrp_campaign_id, cmpusrp_usr_id, cmpusrp_posttype_id)
        CONSTRAINT u277_923"
    EXECUTE IMMEDIATE "ALTER TABLE categories ADD CONSTRAINT
        PRIMARY KEY (ctgr_id)
        CONSTRAINT u262_841"
    EXECUTE IMMEDIATE "ALTER TABLE categories ADD CONSTRAINT
        UNIQUE (ctgr_name)
        CONSTRAINT u262_840"
    EXECUTE IMMEDIATE "ALTER TABLE cities ADD CONSTRAINT
        PRIMARY KEY (cts_id)
        CONSTRAINT u222_642"
    EXECUTE IMMEDIATE "ALTER TABLE countries ADD CONSTRAINT
        PRIMARY KEY (cntr_id)
        CONSTRAINT u220_633"
    EXECUTE IMMEDIATE "ALTER TABLE createdby ADD CONSTRAINT
        PRIMARY KEY (crcb_id)
        CONSTRAINT u230_675"
    EXECUTE IMMEDIATE "ALTER TABLE currencies ADD CONSTRAINT
        PRIMARY KEY (crr_id)
        CONSTRAINT u241_712"
    EXECUTE IMMEDIATE "ALTER TABLE genders ADD CONSTRAINT
        PRIMARY KEY (gnd_id)
        CONSTRAINT u224_654"
    EXECUTE IMMEDIATE "ALTER TABLE genders ADD CONSTRAINT
        UNIQUE (gnd_name)
        CONSTRAINT u224_1015"
    EXECUTE IMMEDIATE "ALTER TABLE grouptags ADD CONSTRAINT
        PRIMARY KEY (gtag_id)
        CONSTRAINT u238_702"
    EXECUTE IMMEDIATE "ALTER TABLE grouptagslist ADD CONSTRAINT
        PRIMARY KEY (gtagl_grouptag_id, gtagl_tag_id)
        CONSTRAINT u239_706"
    EXECUTE IMMEDIATE "ALTER TABLE messages ADD CONSTRAINT
        PRIMARY KEY (msg_id, msg_lang)
        CONSTRAINT pk_messages"
    EXECUTE IMMEDIATE "ALTER TABLE notificationtokens ADD CONSTRAINT
        PRIMARY KEY (ntt_id)
        CONSTRAINT u298_1054"
    EXECUTE IMMEDIATE "ALTER TABLE params ADD CONSTRAINT
        PRIMARY KEY (par_id)
        CONSTRAINT u295_1042"
    EXECUTE IMMEDIATE "ALTER TABLE pics ADD CONSTRAINT
        PRIMARY KEY (pic_id)
        CONSTRAINT u253_807"
    EXECUTE IMMEDIATE "ALTER TABLE postdurations ADD CONSTRAINT
        PRIMARY KEY (pstdr_id)
        CONSTRAINT u240_709"
    EXECUTE IMMEDIATE "ALTER TABLE posttypes ADD CONSTRAINT
        PRIMARY KEY (pstt_id)
        CONSTRAINT u232_681"
    EXECUTE IMMEDIATE "ALTER TABLE proposalstatus ADD CONSTRAINT
        PRIMARY KEY (prp_id)
        CONSTRAINT u285_972"
    EXECUTE IMMEDIATE "ALTER TABLE socialnetworks ADD CONSTRAINT
        PRIMARY KEY (scl_id)
        CONSTRAINT u245_730"
    EXECUTE IMMEDIATE "ALTER TABLE states ADD CONSTRAINT
        PRIMARY KEY (stt_id)
        CONSTRAINT u221_638"
    EXECUTE IMMEDIATE "ALTER TABLE tags ADD CONSTRAINT
        PRIMARY KEY (tag_id)
        CONSTRAINT u237_698"
    EXECUTE IMMEDIATE "ALTER TABLE tags ADD CONSTRAINT
        UNIQUE (tag_name)
        CONSTRAINT u237_824"
    EXECUTE IMMEDIATE "ALTER TABLE tagtypes ADD CONSTRAINT
        PRIMARY KEY (tagt_id)
        CONSTRAINT u236_695"
    EXECUTE IMMEDIATE "ALTER TABLE usermetrics ADD CONSTRAINT
        PRIMARY KEY (usrmtc_id)
        CONSTRAINT u244_726"
    EXECUTE IMMEDIATE "ALTER TABLE userpostprices ADD CONSTRAINT
        PRIMARY KEY (usrpp_usr_id, usrpp_posttype_id)
        CONSTRAINT u243_723"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT
        PRIMARY KEY (usr_id)
        CONSTRAINT u261_715"
    EXECUTE IMMEDIATE "ALTER TABLE usersocialnetworks ADD CONSTRAINT
        PRIMARY KEY (usrscl_id)
        CONSTRAINT u246_733"
    EXECUTE IMMEDIATE "ALTER TABLE notificationtokens ADD CONSTRAINT 
        FOREIGN KEY (ntt_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT fk_notificationtokens_users"
    EXECUTE IMMEDIATE "ALTER TABLE states ADD CONSTRAINT 
        FOREIGN KEY (stt_country_id)
        REFERENCES countries (cntr_id)
        CONSTRAINT r221_755"
    EXECUTE IMMEDIATE "ALTER TABLE cities ADD CONSTRAINT 
        FOREIGN KEY (cts_state_id)
        REFERENCES states (stt_id)
        CONSTRAINT r222_754"
    EXECUTE IMMEDIATE "ALTER TABLE brandcategories ADD CONSTRAINT 
        FOREIGN KEY (brndcat_brand_id)
        REFERENCES brands (brnd_id)
        CONSTRAINT r228_761"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncategories ADD CONSTRAINT 
        FOREIGN KEY (cmpcat_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r231_772"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposttypes ADD CONSTRAINT 
        FOREIGN KEY (cmppst_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r233_797"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposttypes ADD CONSTRAINT 
        FOREIGN KEY (cmppst_posttype_id)
        REFERENCES posttypes (pstt_id)
        CONSTRAINT r233_798"
    EXECUTE IMMEDIATE "ALTER TABLE campaigntags ADD CONSTRAINT 
        FOREIGN KEY (cmptg_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r235_775"
    EXECUTE IMMEDIATE "ALTER TABLE campaigntags ADD CONSTRAINT 
        FOREIGN KEY (cmptg_tag_id)
        REFERENCES tags (tag_id)
        CONSTRAINT r235_776"
    EXECUTE IMMEDIATE "ALTER TABLE tags ADD CONSTRAINT 
        FOREIGN KEY (tag_type_id)
        REFERENCES tagtypes (tagt_id)
        CONSTRAINT r237_777"
    EXECUTE IMMEDIATE "ALTER TABLE grouptagslist ADD CONSTRAINT 
        FOREIGN KEY (gtagl_tag_id)
        REFERENCES grouptags (gtag_id)
        CONSTRAINT r239_778"
    EXECUTE IMMEDIATE "ALTER TABLE grouptagslist ADD CONSTRAINT 
        FOREIGN KEY (gtagl_tag_id)
        REFERENCES tags (tag_id)
        CONSTRAINT r239_779"
    EXECUTE IMMEDIATE "ALTER TABLE userpostprices ADD CONSTRAINT 
        FOREIGN KEY (usrpp_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT r243_785"
    EXECUTE IMMEDIATE "ALTER TABLE userpostprices ADD CONSTRAINT 
        FOREIGN KEY (usrpp_posttype_id)
        REFERENCES posttypes (pstt_id)
        CONSTRAINT r243_786"
    EXECUTE IMMEDIATE "ALTER TABLE usermetrics ADD CONSTRAINT 
        FOREIGN KEY (usrmtc_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT r244_1029"
    EXECUTE IMMEDIATE "ALTER TABLE usersocialnetworks ADD CONSTRAINT 
        FOREIGN KEY (usrscl_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT r246_787"
    EXECUTE IMMEDIATE "ALTER TABLE usersocialnetworks ADD CONSTRAINT 
        FOREIGN KEY (usrscl_socialnetwork_id)
        REFERENCES socialnetworks (scl_id)
        CONSTRAINT r246_788"
    EXECUTE IMMEDIATE "ALTER TABLE boroleperations ADD CONSTRAINT 
        FOREIGN KEY (borlop_borole_id)
        REFERENCES boroles (borl_id)
        CONSTRAINT r250_794"
    EXECUTE IMMEDIATE "ALTER TABLE boroleperations ADD CONSTRAINT 
        FOREIGN KEY (borlop_booperation_id)
        REFERENCES booperations (boop_id)
        CONSTRAINT r250_795"
    EXECUTE IMMEDIATE "ALTER TABLE campaignphotos ADD CONSTRAINT 
        FOREIGN KEY (cmpph_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r257_820"
    EXECUTE IMMEDIATE "ALTER TABLE campaignphotos ADD CONSTRAINT 
        FOREIGN KEY (cmpph_pic_id)
        REFERENCES pics (pic_id)
        CONSTRAINT r257_821"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_gender_id)
        REFERENCES genders (gnd_id)
        CONSTRAINT r258_789"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_country_id)
        REFERENCES countries (cntr_id)
        CONSTRAINT r258_790"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_state_id)
        REFERENCES states (stt_id)
        CONSTRAINT r258_791"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_city_id)
        REFERENCES cities (cts_id)
        CONSTRAINT r258_792"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_usrrole_id)
        REFERENCES boroles (borl_id)
        CONSTRAINT r258_793"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_pic_id)
        REFERENCES pics (pic_id)
        CONSTRAINT r258_813"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers ADD CONSTRAINT 
        FOREIGN KEY (bousr_accountstatus_id)
        REFERENCES accountstatus (accst_id)
        CONSTRAINT r258_835"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_country_id)
        REFERENCES countries (cntr_id)
        CONSTRAINT r260_756"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_state_id)
        REFERENCES states (stt_id)
        CONSTRAINT r260_757"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_city_id)
        REFERENCES cities (cts_id)
        CONSTRAINT r260_758"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_gender_id)
        REFERENCES genders (gnd_id)
        CONSTRAINT r260_759"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_accountstatus_id)
        REFERENCES accountstatus (accst_id)
        CONSTRAINT r260_760"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_pic_id)
        REFERENCES pics (pic_id)
        CONSTRAINT r260_811"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_createdby_id)
        REFERENCES createdby (crcb_id)
        CONSTRAINT r260_827"
    EXECUTE IMMEDIATE "ALTER TABLE brands ADD CONSTRAINT 
        FOREIGN KEY (brnd_currency_id)
        REFERENCES currencies (crr_id)
        CONSTRAINT r260_843"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_gender_id)
        REFERENCES genders (gnd_id)
        CONSTRAINT r261_780"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_country_id)
        REFERENCES countries (cntr_id)
        CONSTRAINT r261_781"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_state_id)
        REFERENCES states (stt_id)
        CONSTRAINT r261_782"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_city_id)
        REFERENCES cities (cts_id)
        CONSTRAINT r261_783"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_currency_id)
        REFERENCES currencies (crr_id)
        CONSTRAINT r261_784"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_accountstatus_id)
        REFERENCES accountstatus (accst_id)
        CONSTRAINT r261_796"
    EXECUTE IMMEDIATE "ALTER TABLE users ADD CONSTRAINT 
        FOREIGN KEY (usr_createdby_id)
        REFERENCES createdby (crcb_id)
        CONSTRAINT r261_829"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncountries ADD CONSTRAINT 
        FOREIGN KEY (cmpcntr_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r267_871"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncountries ADD CONSTRAINT 
        FOREIGN KEY (cmpcntr_country_id)
        REFERENCES countries (cntr_id)
        CONSTRAINT r267_872"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstates ADD CONSTRAINT 
        FOREIGN KEY (cmpstt_campaigncountry_id)
        REFERENCES campaigncountries (cmpcntr_id)
        CONSTRAINT r268_873"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstates ADD CONSTRAINT 
        FOREIGN KEY (cmpstt_state_id)
        REFERENCES states (stt_id)
        CONSTRAINT r268_874"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncities ADD CONSTRAINT 
        FOREIGN KEY (cmpcts_campaignstate_id)
        REFERENCES campaignstates (cmpstt_id)
        CONSTRAINT r269_875"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncities ADD CONSTRAINT 
        FOREIGN KEY (cmpcts_city_id)
        REFERENCES cities (cts_id)
        CONSTRAINT r269_876"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserlist ADD CONSTRAINT 
        FOREIGN KEY (cmpusrl_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r273_921"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserlist ADD CONSTRAINT 
        FOREIGN KEY (cmpusrl_user_id)
        REFERENCES users (usr_id)
        CONSTRAINT r273_922"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_brand_id)
        REFERENCES brands (brnd_id)
        CONSTRAINT r276_763"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_postduration_id)
        REFERENCES postdurations (pstdr_id)
        CONSTRAINT r276_768"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_campaignstatus_id)
        REFERENCES campaignstatus (cmpst_id)
        CONSTRAINT r276_769"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_currency_id)
        REFERENCES currencies (crr_id)
        CONSTRAINT r276_770"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_createdby_id)
        REFERENCES createdby (crcb_id)
        CONSTRAINT r276_771"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns ADD CONSTRAINT 
        FOREIGN KEY (cmp_pic_id)
        REFERENCES pics (pic_id)
        CONSTRAINT r276_815"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices ADD CONSTRAINT 
        FOREIGN KEY (cmpusrp_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r277_928"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices ADD CONSTRAINT 
        FOREIGN KEY (cmpusrp_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT r277_929"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices ADD CONSTRAINT 
        FOREIGN KEY (cmpusrp_posttype_id)
        REFERENCES posttypes (pstt_id)
        CONSTRAINT r277_930"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts ADD CONSTRAINT 
        FOREIGN KEY (cmppost_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r288_1002"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts ADD CONSTRAINT 
        FOREIGN KEY (cmppost_usr_id)
        REFERENCES users (usr_id)
        CONSTRAINT r288_1003"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts ADD CONSTRAINT 
        FOREIGN KEY (cmppost_posttype_id)
        REFERENCES posttypes (pstt_id)
        CONSTRAINT r288_1004"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts ADD CONSTRAINT 
        FOREIGN KEY (cmppost_status_id)
        REFERENCES campaignpoststatus (cmppstst_id)
        CONSTRAINT r288_1005"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpostshist ADD CONSTRAINT 
        FOREIGN KEY (cmpposth_campaignpost_id)
        REFERENCES campaignposts (cmppost_id)
        CONSTRAINT r289_1011"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpostshist ADD CONSTRAINT 
        FOREIGN KEY (cmpposth_status_id)
        REFERENCES campaignpoststatus (cmppstst_id)
        CONSTRAINT r289_1012"
    EXECUTE IMMEDIATE "ALTER TABLE campaigngenders ADD CONSTRAINT 
        FOREIGN KEY (cmpgen_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r290_1019"
    EXECUTE IMMEDIATE "ALTER TABLE campaigngenders ADD CONSTRAINT 
        FOREIGN KEY (cmpgen_gender_id)
        REFERENCES genders (gnd_id)
        CONSTRAINT r290_1020"
    EXECUTE IMMEDIATE "ALTER TABLE brandsocialnetworks ADD CONSTRAINT 
        FOREIGN KEY (brndscl_brand_id)
        REFERENCES brands (brnd_id)
        CONSTRAINT r291_1027"
    EXECUTE IMMEDIATE "ALTER TABLE brandsocialnetworks ADD CONSTRAINT 
        FOREIGN KEY (brndscl_socialnetwork_id)
        REFERENCES socialnetworks (scl_id)
        CONSTRAINT r291_1028"
    EXECUTE IMMEDIATE "ALTER TABLE campaignshist ADD CONSTRAINT 
        FOREIGN KEY (cmph_campaign_id)
        REFERENCES campaigns (cmp_id)
        CONSTRAINT r292_1035"
    EXECUTE IMMEDIATE "ALTER TABLE campaignshist ADD CONSTRAINT 
        FOREIGN KEY (cmph_campaignstatus_id)
        REFERENCES campaignstatus (cmpst_id)
        CONSTRAINT r292_1036"

END FUNCTION

#+ Drop all constraints from all tables.
FUNCTION db_drop_constraints()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "ALTER TABLE notificationtokens DROP CONSTRAINT fk_notificationtokens_users"
    EXECUTE IMMEDIATE "ALTER TABLE states DROP CONSTRAINT r221_755"
    EXECUTE IMMEDIATE "ALTER TABLE cities DROP CONSTRAINT r222_754"
    EXECUTE IMMEDIATE "ALTER TABLE brandcategories DROP CONSTRAINT r228_761"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncategories DROP CONSTRAINT r231_772"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposttypes DROP CONSTRAINT r233_797"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposttypes DROP CONSTRAINT r233_798"
    EXECUTE IMMEDIATE "ALTER TABLE campaigntags DROP CONSTRAINT r235_775"
    EXECUTE IMMEDIATE "ALTER TABLE campaigntags DROP CONSTRAINT r235_776"
    EXECUTE IMMEDIATE "ALTER TABLE tags DROP CONSTRAINT r237_777"
    EXECUTE IMMEDIATE "ALTER TABLE grouptagslist DROP CONSTRAINT r239_778"
    EXECUTE IMMEDIATE "ALTER TABLE grouptagslist DROP CONSTRAINT r239_779"
    EXECUTE IMMEDIATE "ALTER TABLE userpostprices DROP CONSTRAINT r243_785"
    EXECUTE IMMEDIATE "ALTER TABLE userpostprices DROP CONSTRAINT r243_786"
    EXECUTE IMMEDIATE "ALTER TABLE usermetrics DROP CONSTRAINT r244_1029"
    EXECUTE IMMEDIATE "ALTER TABLE usersocialnetworks DROP CONSTRAINT r246_787"
    EXECUTE IMMEDIATE "ALTER TABLE usersocialnetworks DROP CONSTRAINT r246_788"
    EXECUTE IMMEDIATE "ALTER TABLE boroleperations DROP CONSTRAINT r250_794"
    EXECUTE IMMEDIATE "ALTER TABLE boroleperations DROP CONSTRAINT r250_795"
    EXECUTE IMMEDIATE "ALTER TABLE campaignphotos DROP CONSTRAINT r257_820"
    EXECUTE IMMEDIATE "ALTER TABLE campaignphotos DROP CONSTRAINT r257_821"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_789"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_790"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_791"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_792"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_793"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_813"
    EXECUTE IMMEDIATE "ALTER TABLE backofficeusers DROP CONSTRAINT r258_835"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_756"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_757"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_758"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_759"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_760"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_811"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_827"
    EXECUTE IMMEDIATE "ALTER TABLE brands DROP CONSTRAINT r260_843"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_780"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_781"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_782"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_783"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_784"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_796"
    EXECUTE IMMEDIATE "ALTER TABLE users DROP CONSTRAINT r261_829"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncountries DROP CONSTRAINT r267_871"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncountries DROP CONSTRAINT r267_872"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstates DROP CONSTRAINT r268_873"
    EXECUTE IMMEDIATE "ALTER TABLE campaignstates DROP CONSTRAINT r268_874"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncities DROP CONSTRAINT r269_875"
    EXECUTE IMMEDIATE "ALTER TABLE campaigncities DROP CONSTRAINT r269_876"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserlist DROP CONSTRAINT r273_921"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserlist DROP CONSTRAINT r273_922"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_763"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_768"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_769"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_770"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_771"
    EXECUTE IMMEDIATE "ALTER TABLE campaigns DROP CONSTRAINT r276_815"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices DROP CONSTRAINT r277_928"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices DROP CONSTRAINT r277_929"
    EXECUTE IMMEDIATE "ALTER TABLE campaignuserprices DROP CONSTRAINT r277_930"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts DROP CONSTRAINT r288_1002"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts DROP CONSTRAINT r288_1003"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts DROP CONSTRAINT r288_1004"
    EXECUTE IMMEDIATE "ALTER TABLE campaignposts DROP CONSTRAINT r288_1005"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpostshist DROP CONSTRAINT r289_1011"
    EXECUTE IMMEDIATE "ALTER TABLE campaignpostshist DROP CONSTRAINT r289_1012"
    EXECUTE IMMEDIATE "ALTER TABLE campaigngenders DROP CONSTRAINT r290_1019"
    EXECUTE IMMEDIATE "ALTER TABLE campaigngenders DROP CONSTRAINT r290_1020"
    EXECUTE IMMEDIATE "ALTER TABLE brandsocialnetworks DROP CONSTRAINT r291_1027"
    EXECUTE IMMEDIATE "ALTER TABLE brandsocialnetworks DROP CONSTRAINT r291_1028"
    EXECUTE IMMEDIATE "ALTER TABLE campaignshist DROP CONSTRAINT r292_1035"
    EXECUTE IMMEDIATE "ALTER TABLE campaignshist DROP CONSTRAINT r292_1036"

END FUNCTION


