DROP TABLE brandcategories ;
DROP TABLE campaigncategories ;
DROP TABLE campaignposttypes ;
DROP TABLE campaignphotos ;
DROP TABLE campaigntags ;
DROP TABLE usersocialnetworks ;
DROP TABLE usermetrics ;
DROP TABLE grouptagslist ;
DROP TABLE boroleperations ;
DROP TABLE userpostprices;

DROP TABLE tags ;
DROP TABLE campaigns ;
DROP TABLE brands ;
DROP TABLE users ;
DROP TABLE backofficeusers ;

DROP TABLE cities ;
DROP TABLE states ;
DROP TABLE countries ;
DROP TABLE genders ;
DROP TABLE categories ;
DROP TABLE accountstatus ;
DROP TABLE campaignstatus ;
DROP TABLE posttypes ;
DROP TABLE postdurations ;
DROP TABLE socialnetworks ;
DROP TABLE grouptags ;
DROP TABLE tagtypes ;
DROP TABLE boroles ;
DROP TABLE booperations ;
DROP TABLE currencies;
DROP TABLE campaigncreatedby ;


CREATE TABLE countries (
cntr_id INTEGER NOT NULL PRIMARY KEY,
cntr_sortname VARCHAR(4) NOT NULL,
cntr_name VARCHAR(64) NOT NULL,
cntr_phonecode INTEGER NOT NULL
);

CREATE TABLE states (
stt_id INTEGER NOT NULL PRIMARY KEY,
stt_name VARCHAR(32) NOT NULL,
stt_country_id INTEGER NOT NULL
);

CREATE TABLE cities (
cts_id INTEGER NOT NULL PRIMARY KEY,
cts_name VARCHAR(32) NOT NULL,
cts_state_id INTEGER NOT NULL
);


CREATE TABLE brands (
brnd_id SERIAL NOT NULL PRIMARY KEY,
brnd_profilepicture BYTE,
brnd_name VARCHAR(128) NOT NULL,
brnd_website VARCHAR(255),
brnd_country_id INTEGER NOT NULL,
brnd_state_id INTEGER,
brnd_city_id INTEGER,
brnd_gender_id INTEGER,
brnd_firstname VARCHAR(128),
brnd_lastname VARCHAR(128),
brnd_email VARCHAR(128) NOT NULL,
brnd_password VARCHAR(255) NOT NULL,
brnd_mobile_phonenumber VARCHAR(32),
brnd_accountstatus_id INTEGER NOT NULL,
brnd_creationdate DATETIME YEAR TO SECOND NOT NULL,  --date of account creation by the brand/salfatix
brnd_updatedate DATETIME YEAR TO SECOND, --date of account update by the brand
brnd_deletiondate DATETIME YEAR TO SECOND, --date of account deletion by the brand
brnd_validationdate DATETIME YEAR TO SECOND, --date of account validation by salfatix
brnd_canceldate DATETIME YEAR TO SECOND,--date of account cancellation by salfatix
brnd_suspendeddate DATETIME YEAR TO SECOND, --date of account suspension by salfatix
brnd_emailvalidationdate DATETIME YEAR TO SECOND,--date of email account validation by brand
brnd_lastupdatedate DATETIME YEAR TO SECOND,
brnd_lastlogindate DATETIME YEAR TO SECOND
);

CREATE TABLE genders (
gnd_id INTEGER NOT NULL PRIMARY KEY,
gnd_name VARCHAR(16) NOT NULL
); --Not specified | Female | Male

CREATE TABLE categories (
ctgr_id INTEGER NOT NULL PRIMARY KEY,
ctgr_name VARCHAR(32) NOT NULL
); --Fashion | Fitness | Beauty | Swimwear | Luxury | Travel | Food | Music | Tech | Other

CREATE TABLE accountstatus (
accst_id INTEGER NOT NULL PRIMARY KEY,
accst_name VARCHAR(32) NOT NULL
); --"Created" | "Deleted"
   --"Cancelled" | "Incompleted" | "Validated"  | "Suspended" only be done by Salfatix

CREATE TABLE campaignstatus (
cmpst_id INTEGER NOT NULL PRIMARY KEY,
cmpst_name VARCHAR(32) NOT NULL
); --"Created" | "Cancelled" | "Suspended" | "Deposit Paid" | "Paid" | "Online" 

CREATE TABLE brandcategories (
brndcat_brand_id INTEGER NOT NULL,
brndcat_category_id INTEGER NOT NULL,
PRIMARY KEY (brndcat_brand_id, brndcat_category_id)
);

CREATE TABLE campaigns (
cmp_id SERIAL NOT NULL PRIMARY KEY,
cmp_brand_id INTEGER NOT NULL,
cmp_photo BYTE,
cmp_title VARCHAR(64),
cmp_overview VARCHAR(255),
cmp_url VARCHAR(255),
cmp_gender_id INTEGER,
cmp_country_id INTEGER,
cmp_state_id INTEGER,
cmp_city_id INTEGER,
cmp_prd_description VARCHAR(255),
cmp_prd_value INTEGER,
cmp_post_guidelines VARCHAR(128),
--list of user tags -- list of hashtags
cmp_captionrequirements VARCHAR(255),
cmp_post_startdate DATE,
cmp_post_time_day INTEGER, -- 1->Monday, 2->Tuesday...7->Sunday
cmp_post_time_starttime INTEGER, --0->23
cmp_post_time_endtime INTEGER, --0->23
cmp_postduration_id INTEGER,
cmp_totalbudget DECIMAL(10,2),
cmp_deposit DECIMAL(10,2),
cmp_depositpercent DECIMAL(6,2),
cmp_currency_id INTEGER,
cmp_depositrequestdate DATETIME YEAR TO SECOND,
cmp_depositpaymentdate DATETIME YEAR TO SECOND,
cmp_totalpaymentdate DATETIME YEAR TO SECOND,
cmp_campaignstatus_id INTEGER NOT NULL,
cmp_campaigncreatedby_id INTEGER NOT NULL,
cmp_creationdate DATETIME YEAR TO SECOND NOT NULL,
cmp_updatedate DATETIME YEAR TO SECOND, --date of campaign update by brand/salfatix
cmp_validationdate DATETIME YEAR TO SECOND, --date of deal validation by salfatix
cmp_deletiondate DATETIME YEAR TO SECOND, --date of deal deletion by the brand
cmp_canceldate DATETIME YEAR TO SECOND,
cmp_suspendeddate DATETIME YEAR TO SECOND, --date of deal suspension by salfatix
cmp_startdate DATETIME YEAR TO SECOND,
cmp_selectionstartdate DATETIME YEAR TO SECOND, --starttime to accept of reject campaign by influencers
cmp_selectionenddate DATETIME YEAR TO SECOND,
cmp_actionstartdate DATETIME YEAR TO SECOND,
cmp_actionenddate DATETIME YEAR TO SECOND,
cmp_enddate DATETIME YEAR TO SECOND,
cmp_lastupdatedate DATETIME YEAR TO SECOND
);

CREATE TABLE campaigncreatedby (
cmpcb_id INTEGER NOT NULL PRIMARY KEY,
cmpcb_name VARCHAR(32) NOT NULL
); --"Brand" | "SalfatixMedia" | "Brand with SalfatixMedia" 

CREATE TABLE campaigncategories (
cmpcat_campaign_id INTEGER NOT NULL,
cmpcat_category_id INTEGER NOT NULL,
PRIMARY KEY (cmpcat_campaign_id, cmpcat_category_id)
);

CREATE TABLE posttypes (
pstt_id INTEGER NOT NULL PRIMARY KEY,
pstt_name VARCHAR(32) NOT NULL
); --"photos" | "videos" | "stories"

CREATE TABLE campaignposttypes (
cmppst_campaign_id INTEGER NOT NULL,
cmppst_posttype_id INTEGER NOT NULL,
PRIMARY KEY (cmppst_campaign_id, cmppst_posttype_id)
);

CREATE TABLE campaignphotos (
cmpph_id SERIAL NOT NULL PRIMARY KEY,
cmpph_campaign_id INTEGER NOT NULL,
cmpph_photo BYTE NOT NULL,
cmpph_creationdate DATETIME YEAR TO SECOND NOT NULL
);

CREATE TABLE campaigntags (
cmptg_campaign_id INTEGER NOT NULL,
cmptg_tag_id INTEGER NOT NULL,
PRIMARY KEY(cmptg_campaign_id, cmptg_tag_id)
);

CREATE TABLE tagtypes (
tagt_id INTEGER NOT NULL PRIMARY KEY,
tagt_name VARCHAR(16) NOT NULL --"hashtag" - "usertag"
);

CREATE TABLE tags (
tag_id SERIAL NOT NULL PRIMARY KEY,
tag_name VARCHAR(128) NOT NULL,
tag_type_id INTEGER, --#hashtag or @usertag
tag_creationdate DATETIME YEAR TO SECOND NOT NULL
);

CREATE TABLE grouptags (
gtag_id SERIAL NOT NULL PRIMARY KEY,
gtag_name VARCHAR(128) NOT NULL,
gtag_creationdate DATETIME YEAR TO SECOND NOT NULL
);

CREATE TABLE grouptagslist (
gtagl_grouptag_id INTEGER NOT NULL,
gtagl_tag_id INTEGER NOT NULL,
PRIMARY KEY(gtagl_grouptag_id, gtagl_tag_id)
);

CREATE TABLE postdurations (
pstdr_id INTEGER NOT NULL PRIMARY KEY,
pstdr_name VARCHAR(32) NOT NULL --"1 Month", "1 Day", "1 Week", "Permanent"
);

CREATE TABLE currencies (
crr_id INTEGER NOT NULL PRIMARY KEY,
crr_name VARCHAR(32) NOT NULL,
crr_symbol VARCHAR(8)
);

CREATE TABLE users (
usr_id SERIAL NOT NULL PRIMARY KEY,
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
usr_mobile_phone VARCHAR(32),
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
usr_mobile_notifications SMALLINT,
usr_sms_notifications SMALLINT,
usr_email_notifications SMALLINT,
usr_currency_id INTEGER,
usr_accountstatus_id INTEGER NOT NULL,
usr_creationdate DATETIME YEAR TO SECOND NOT NULL, --date of account creation by the usr/salfatix
usr_updatedate DATETIME YEAR TO SECOND, --date of account update by the usr/salfatix
usr_deletiondate DATETIME YEAR TO SECOND, --date of account deletion by the usr
usr_validationdate DATETIME YEAR TO SECOND, --date of account validation by salfatix
usr_canceldate DATETIME YEAR TO SECOND, --date of account cancellation by salfatix
usr_suspendeddate DATETIME YEAR TO SECOND, --date of account suspension by salfatix
usr_rejecteddate DATETIME YEAR TO SECOND, --date of account rejection by salfatix
usr_emailvalidationdate DATETIME YEAR TO SECOND, --date of email account validation by usr
usr_lastupdatedate DATETIME YEAR TO SECOND,
usr_lastlogindate DATETIME YEAR TO SECOND
); 

CREATE TABLE userpostprices (
usrpp_usr_id INTEGER NOT NULL,
usrpp_posttype_id INTEGER NOT NULL,
usrpp_price DECIMAL(10,2),
PRIMARY KEY(usrpp_usr_id, usrpp_posttype_id)
);

--only for instagram
CREATE TABLE usermetrics (
usrmtc_id SERIAL NOT NULL PRIMARY KEY,
usrmtc_socialnetwork_id INTEGER NOT NULL,
usrmtc_instagram_userid BIGINT,
usrmtc_instagram_username VARCHAR(128),
usrmtc_geomedia_count INTEGER,
usrmtc_media_count INTEGER,
usrmtc_follows_count INTEGER,
usrmtc_followers_count INTEGER,
usrmtc_comments_count INTEGER,
usrmtc_likes_count INTEGER,
usrmtc_usertags_count INTEGER,
usrmtc_bdate DATETIME YEAR TO SECOND NOT NULL,
usrmtc_edate DATETIME YEAR TO SECOND NOT NULL
);

CREATE TABLE socialnetworks (
scl_id INTEGER NOT NULL PRIMARY KEY,
scl_name VARCHAR(64) NOT NULL
); --FaceBook | Twitter | Instagram | Youtube | Linkedin | Pinterest | SkyBlog etc...

--should be an association table but I use a SERIAL as PK so an user can have several youtube accounts 
CREATE TABLE usersocialnetworks (
usrscl_id SERIAL NOT NULL PRIMARY KEY,
usrscl_user_id INTEGER NOT NULL,
usrscl_socialnetwork_id INTEGER NOT NULL,
usrscl_website VARCHAR(255)
);

CREATE TABLE backofficeusers (
bousr_id SERIAL NOT NULL PRIMARY KEY,
bousr_login VARCHAR(255) NOT NULL,
bousr_password VARCHAR(255) NOT NULL,
bousr_profilepicture BYTE,
bousr_gender_id INTEGER,
bousr_firstname VARCHAR(128),
bousr_lastname VARCHAR(128),
bousr_email VARCHAR(128) NOT NULL,
bousr_country_id INTEGER NOT NULL,
bousr_state_id INTEGER,
bousr_city_id INTEGER,
bousr_address_number VARCHAR(16),
bousr_address_street VARCHAR(128),
bousr_address_zipcode VARCHAR(128),
bousr_address_town VARCHAR(128),
bousr_address_more VARCHAR(128),
bousr_mobile_phone VARCHAR(32),
bousr_isadmin SMALLINT NOT NULL,
bousr_usrrole_id INTEGER,
bousr_creationdate DATETIME YEAR TO SECOND NOT NULL, --date of account creation by the usr/salfatix
bousr_updatedate DATETIME YEAR TO SECOND, --date of account update by the usr/salfatix
bousr_deletiondate DATETIME YEAR TO SECOND, --date of account deletion by the usr
bousr_suspendeddate DATETIME YEAR TO SECOND, --date of account suspension by salfatix
bousr_lastupdatedate DATETIME YEAR TO SECOND,
bousr_lastlogindate DATETIME YEAR TO SECOND
); 

CREATE TABLE boroles (
borl_id SERIAL NOT NULL PRIMARY KEY,
borl_name VARCHAR(64) NOT NULL
);

CREATE TABLE booperations (
boop_id INTEGER NOT NULL PRIMARY KEY,
boop_name VARCHAR(64) NOT NULL
);

CREATE TABLE boroleperations (
borlop_borole_id INTEGER NOT NULL,
borlop_booperation_id INTEGER NOT NULL,
PRIMARY KEY(borlop_borole_id, borlop_booperation_id)
);

INSERT INTO genders VALUES (1,"Not specified");
INSERT INTO genders VALUES (2,"Male");
INSERT INTO genders VALUES (3,"Female");

INSERT INTO categories VALUES (1,"Fashion");
INSERT INTO categories VALUES (2,"Fitness");
INSERT INTO categories VALUES (3,"Beauty");
INSERT INTO categories VALUES (4,"Swimwear");
INSERT INTO categories VALUES (5,"Luxury");
INSERT INTO categories VALUES (6,"Travel");
INSERT INTO categories VALUES (7,"Food");
INSERT INTO categories VALUES (8,"Music");
INSERT INTO categories VALUES (9,"Tech");

INSERT INTO currencies VALUES (1, "Euro", "€");

INSERT INTO campaigncreatedby VALUES (1, "Brand");
INSERT INTO campaigncreatedby VALUES (2, "SalfatixMedia");
INSERT INTO campaigncreatedby VALUES (3, "Brand helped by SalfatixMedia");

INSERT INTO accountstatus VALUES(1,"Created");
INSERT INTO accountstatus VALUES(2,"Cancelled");
INSERT INTO accountstatus VALUES(3,"Incomplete");
INSERT INTO accountstatus VALUES(4,"Validated");
INSERT INTO accountstatus VALUES(5,"Suspended");
INSERT INTO accountstatus VALUES(6,"Deleted");

INSERT INTO campaignstatus VALUES(1,"Created");
INSERT INTO campaignstatus VALUES(2,"Cancelled");
INSERT INTO campaignstatus VALUES(3,"Suspended");
INSERT INTO campaignstatus VALUES(4,"Deposit Paid");
INSERT INTO campaignstatus VALUES(5,"Paid");
INSERT INTO campaignstatus VALUES(6,"Online");

INSERT INTO posttypes VALUES (1,"Photos");
INSERT INTO posttypes VALUES (2,"Videos");
INSERT INTO posttypes VALUES (3,"Stories");

INSERT INTO postdurations VALUES (1, "1 Month");
INSERT INTO postdurations VALUES (2, "1 Day");
INSERT INTO postdurations VALUES (3, "1 Week");
INSERT INTO postdurations VALUES (4, "Permanent");

INSERT INTO tagtypes VALUES (1, "Hashtag");
INSERT INTO tagtypes VALUES (2, "Usertag");

INSERT INTO socialnetworks VALUES (1, "Instagram");
INSERT INTO socialnetworks VALUES (2, "Youtube");
INSERT INTO socialnetworks VALUES (3, "Facebook");
INSERT INTO socialnetworks VALUES (4, "Twitter");

INSERT INTO booperations VALUES (200, "Can register a brand account");
INSERT INTO booperations VALUES (201, "Can validate a brand account");
INSERT INTO booperations VALUES (202, "Can update a brand account");
INSERT INTO booperations VALUES (203, "Can cancel a brand account");
INSERT INTO booperations VALUES (204, "Can suspend a brand account");

INSERT INTO booperations VALUES (300, "Can register an influencer account");
INSERT INTO booperations VALUES (301, "Can validate an influencer account");
INSERT INTO booperations VALUES (302, "Can update an influencer account");
INSERT INTO booperations VALUES (303, "Can cancel an influencer account");
INSERT INTO booperations VALUES (304, "Can suspend an influencer account");

INSERT INTO booperations VALUES (400, "Can register a campaign");
INSERT INTO booperations VALUES (401, "Can validate a campaign");
INSERT INTO booperations VALUES (402, "Can update a campaign");
INSERT INTO booperations VALUES (403, "Can cancel a campaign");
INSERT INTO booperations VALUES (404, "Can suspend a campaign");
INSERT INTO booperations VALUES (405, "Can request campaign payment");

INSERT INTO booperations VALUES (500, "Can create influencer list for a campaign");

INSERT INTO boroles VALUES (1, "Users");

ALTER TABLE cities ADD CONSTRAINT FOREIGN KEY (cts_state_id) REFERENCES states(stt_id);
ALTER TABLE states ADD CONSTRAINT FOREIGN KEY (stt_country_id) REFERENCES countries(cntr_id);

ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_country_id) REFERENCES countries(cntr_id);
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_state_id) REFERENCES states(stt_id);
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_city_id) REFERENCES cities(cts_id);
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_gender_id) REFERENCES genders(gnd_id);
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_accountstatus_id) REFERENCES accountstatus(accst_id);

ALTER TABLE brandcategories ADD CONSTRAINT FOREIGN KEY (brndcat_brand_id) REFERENCES brands(brnd_id);
ALTER TABLE brandcategories ADD CONSTRAINT FOREIGN KEY (brndcat_category_id) REFERENCES categories(ctgr_id);

ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_brand_id) REFERENCES brands(brnd_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_gender_id) REFERENCES genders(gnd_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_country_id) REFERENCES countries(cntr_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_state_id) REFERENCES states(stt_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_city_id) REFERENCES cities(cts_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_postduration_id) REFERENCES postdurations(pstdr_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_campaignstatus_id) REFERENCES campaignstatus(cmpst_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_currency_id) REFERENCES currencies(crr_id);
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_campaigncreatedby_id) REFERENCES campaigncreatedby(cmpcb_id);

ALTER TABLE campaigncategories ADD CONSTRAINT FOREIGN KEY (cmpcat_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaigncategories ADD CONSTRAINT FOREIGN KEY (cmpcat_category_id) REFERENCES categories(ctgr_id);

ALTER TABLE campaignposttypes ADD CONSTRAINT FOREIGN KEY (cmppst_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignposttypes ADD CONSTRAINT FOREIGN KEY (cmppst_posttype_id) REFERENCES posttypes(pstt_id);

ALTER TABLE campaignphotos ADD CONSTRAINT FOREIGN KEY (cmpph_campaign_id) REFERENCES campaigns(cmp_id);

ALTER TABLE campaigntags ADD CONSTRAINT FOREIGN KEY (cmptg_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaigntags ADD CONSTRAINT FOREIGN KEY (cmptg_tag_id) REFERENCES tags(tag_id);

ALTER TABLE tags ADD CONSTRAINT FOREIGN KEY (tag_type_id) REFERENCES tagtypes(tagt_id);

ALTER TABLE grouptagslist ADD CONSTRAINT FOREIGN KEY (gtagl_tag_id) REFERENCES grouptags(gtag_id);
ALTER TABLE grouptagslist ADD CONSTRAINT FOREIGN KEY (gtagl_tag_id) REFERENCES tags(tag_id);

ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_gender_id) REFERENCES genders(gnd_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_country_id) REFERENCES countries(cntr_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_state_id) REFERENCES states(stt_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_city_id) REFERENCES cities(cts_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_currency_id) REFERENCES currencies(crr_id);
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_accountstatus_id) REFERENCES accountstatus(accst_id);

ALTER TABLE userpostprices ADD CONSTRAINT FOREIGN KEY (usrpp_usr_id) REFERENCES users(usr_id);
ALTER TABLE userpostprices ADD CONSTRAINT FOREIGN KEY (usrpp_posttype_id) REFERENCES posttypes(pstt_id);

ALTER TABLE usersocialnetworks ADD CONSTRAINT FOREIGN KEY (usrscl_user_id) REFERENCES users(usr_id);
ALTER TABLE usersocialnetworks ADD CONSTRAINT FOREIGN KEY (usrscl_socialnetwork_id) REFERENCES socialnetworks(scl_id);

ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_gender_id) REFERENCES genders(gnd_id);
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_country_id) REFERENCES countries(cntr_id);
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_state_id) REFERENCES states(stt_id);
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_city_id) REFERENCES cities(cts_id);
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_usrrole_id) REFERENCES boroles(borl_id);

ALTER TABLE boroleperations ADD CONSTRAINT FOREIGN KEY (borlop_borole_id) REFERENCES boroles(borl_id);
ALTER TABLE boroleperations ADD CONSTRAINT FOREIGN KEY (borlop_booperation_id) REFERENCES booperations(boop_id);

ALTER TABLE usermetrics ADD CONSTRAINT FOREIGN KEY (usrmtc_socialnetwork_id) REFERENCES socialnetworks(scl_id);

{
--in progress : add new table to store the differents lists sent to the brand
CREATE TABLE campaignuserlist ( --created a list of influencers for a campaign
cmpusrl_id SERIAL NOT NULL PRIMARY KEY,
cmpusrl_campaign_id INTEGER NOT NULL,
cmpusrl_allusers SMALLINT NOT NULL,
cmpusrl_creationdate DATETIME YEAR TO SECOND NOT NULL, --date of user list creation by the salfatix
cmpusrl_previewnotificationdate DATETIME YEAR TO SECOND NOT NULL, --date of notifications of "avant-premiere" users in the list by salfatix
cmpusrl_notificationdate DATETIME YEAR TO SECOND NOT NULL, --date of notifications of users in the list by salfatix
cmpusrl_proposaldate DATETIME YEAR TO SECOND NOT NULL, --proposal of influencers list
cmpusrl_brandanswerdate DATETIME YEAR TO SECOND NOT NULL, --date of validation of the list by the brand
cmpusrl_isapproved SMALLINT --1->approved by brand
);

CREATE TABLE userslist ( --list of users
usrl_id SERIAL NOT NULL PRIMARY KEY,
usrl_campaignuserlist_id INTEGER NOT NULL,
usrl_user_id INTEGER,
usrl_user_email VARCHAR(128), --TOOD : use field cmpusr_usr_email to identify influencer that are not in the database
usrl_wantedbybrand SMALLINT,
usrl_previewuser SMALLINT, --indicates if the user is a privileged user and received the notification before other people
usrl_notificationdate DATETIME YEAR TO SECOND NOT NULL, --user notifcation date
usrl_useranswerdate DATETIME YEAR TO SECOND NOT NULL,
usrl_isacceptbyuser SMALLINT, --1->apply, 0->reject, null->no answer
usrl_isproposed SMALLINT, --user is selected by salfatix and submitted to brand approval
usrl_proposalorder INTEGER, --display order in the selection 
usrl_isrejectedbybrand SMALLINT,
usrl_finalnotificationdate DATETIME YEAR TO SECOND NOT NULL, --user gets notification when brand has chosen him
);
}

CREATE TABLE pics (
  pic_id SERIAL NOT NULL PRIMARY KEY,
  pic_value BYTE NOT NULL
);

ALTER TABLE brands DROP brnd_profilepicture;
DELETE FROM brands WHERE 1=1;
ALTER TABLE brands ADD brnd_pic_id INTEGER NOT NULL BEFORE brnd_name;
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_pic_id) REFERENCES pics(pic_id);

ALTER TABLE backofficeusers DROP bousr_profilepicture;
DELETE FROM backofficeusers WHERE 1=1;
ALTER TABLE backofficeusers ADD bousr_pic_id INTEGER NOT NULL BEFORE bousr_gender_id;
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_pic_id) REFERENCES pics(pic_id);

ALTER TABLE campaigns DROP cmp_photo;
DELETE FROM campaigns WHERE 1=1;
ALTER TABLE campaigns ADD cmp_pic_id INTEGER NOT NULL BEFORE cmp_title;
ALTER TABLE campaigns ADD CONSTRAINT FOREIGN KEY (cmp_pic_id) REFERENCES pics(pic_id);

DROP TABLE campaignphotos;

CREATE TABLE campaignphotos (
cmpph_campaign_id INTEGER NOT NULL,
cmpph_pic_id INTEGER NOT NULL,
cmpph_creationdate DATETIME YEAR TO SECOND NOT NULL,
PRIMARY KEY(cmpph_campaign_id, cmpph_pic_id)
);
ALTER TABLE campaignphotos ADD CONSTRAINT FOREIGN KEY (cmpph_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignphotos ADD CONSTRAINT FOREIGN KEY (cmpph_pic_id) REFERENCES pics(pic_id);

ALTER TABLE backofficeusers MODIFY bousr_mobile_phone BIGINT;
ALTER TABLE brands MODIFY brnd_mobile_phonenumber BIGINT;
ALTER TABLE users MODIFY usr_mobile_phone BIGINT;

INSERT INTO genders VALUES (4,"Male and Female");

ALTER TABLE campaignphotos DROP cmpph_creationdate;

ALTER TABLE tags DROP tag_creationdate;

ALTER TABLE campaignphotos ADD cmpph_uiorder INTEGER NOT NULL;
ALTER TABLE campaigntags ADD cmptg_uiorder INTEGER NOT NULL;
ALTER TABLE tags MODIFY tag_name VARCHAR(128) NOT NULL UNIQUE;

ALTER TABLE users DROP usr_sms_notifications;

ALTER TABLE backofficeusers DROP bousr_login;
INSERT INTO backofficeusers(bousr_id, bousr_password, bousr_pic_id, bousr_gender_id, bousr_firstname, bousr_lastname, bousr_email, bousr_country_id, bousr_isadmin, bousr_creationdate)
VALUES (1, '$2a$10$C7rV3y/kCahvYjUoQchw5OVTI9YQL.eEoQwzEhYPcPRGIJuV3i6Xq', 1, 1, 'Administrator', 'Administrator', 'admin@salfatixmedia.com', 75, 1, CURRENT);

RENAME TABLE campaigncreatedby TO createdby;
RENAME COLUMN createdby.cmpcb_id TO crcb_id;
RENAME COLUMN createdby.cmpcb_name TO crcb_name;
RENAME COLUMN campaigns.cmp_campaigncreatedby_id TO cmp_createdby_id;

ALTER TABLE brands ADD brnd_createdby_id INTEGER BEFORE brnd_creationdate;
UPDATE brands SET brnd_createdby_id = 1 WHERE 1=1;
ALTER TABLE brands MODIFY brnd_createdby_id INTEGER NOT NULL;
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_createdby_id) REFERENCES createdby(crcb_id);

ALTER TABLE users ADD usr_createdby_id INTEGER BEFORE usr_creationdate;
UPDATE users SET usr_createdby_id = 1 WHERE 1=1;
ALTER TABLE users MODIFY usr_createdby_id INTEGER NOT NULL;
ALTER TABLE users ADD CONSTRAINT FOREIGN KEY (usr_createdby_id) REFERENCES createdby(crcb_id);

INSERT INTO createdby VALUES (4, "Influencer");

ALTER TABLE posttypes ADD pstt_uiorder INTEGER;
UPDATE posttypes SET pstt_uiorder = pstt_id WHERE 1=1;
ALTER TABLE posttypes MODIFY pstt_uiorder INTEGER NOT NULL;

ALTER TABLE categories ADD ctgr_uiorder INTEGER;
UPDATE categories SET ctgr_uiorder = ctgr_id WHERE 1=1;
ALTER TABLE categories MODIFY ctgr_uiorder INTEGER NOT NULL;

ALTER TABLE socialnetworks ADD scl_uiorder INTEGER;
UPDATE socialnetworks SET scl_uiorder = scl_id WHERE 1=1;
ALTER TABLE socialnetworks MODIFY scl_uiorder INTEGER NOT NULL;

UPDATE accountstatus SET accst_name = "Completed" WHERE accst_id = 1;

DELETE FROM campaignstatus WHERE cmpst_id <> 1;
INSERT INTO campaignstatus VALUES(2,"Submitted");
INSERT INTO campaignstatus VALUES(3,"Validated");
INSERT INTO campaignstatus VALUES(4,"Deposit Paid");
INSERT INTO campaignstatus VALUES(5,"Influencers Notified");
INSERT INTO campaignstatus VALUES(6,"Registration Closed");
INSERT INTO campaignstatus VALUES(7,"Influencers Proposed");
INSERT INTO campaignstatus VALUES(8,"Influencers Validated");
INSERT INTO campaignstatus VALUES(9,"Fully Paid");
INSERT INTO campaignstatus VALUES(10,"Posts Sent");
INSERT INTO campaignstatus VALUES(11,"Closed");
INSERT INTO campaignstatus VALUES(12,"Deleted");

ALTER TABLE brands DROP brnd_updatedate;
ALTER TABLE users DROP usr_updatedate;
ALTER TABLE backofficeusers DROP bousr_updatedate;
ALTER TABLE backofficeusers DROP bousr_suspendeddate;
ALTER TABLE backofficeusers ADD bousr_accountstatus_id INTEGER BEFORE bousr_creationdate;
UPDATE backofficeusers SET bousr_accountstatus_id = 1 WHERE 1=1;
ALTER TABLE backofficeusers MODIFY bousr_accountstatus_id INTEGER NOT NULL;
ALTER TABLE backofficeusers ADD CONSTRAINT FOREIGN KEY (bousr_accountstatus_id) REFERENCES accountstatus(accst_id);

RENAME COLUMN campaigns.cmp_updatedate TO cmp_submitteddate;

INSERT INTO campaignstatus VALUES(13,"Pending");

UPDATE posttypes SET pstt_name="Instagram-Photos" WHERE pstt_id = 1;
UPDATE posttypes SET pstt_name="Instagram-Videos" WHERE pstt_id = 2;
UPDATE posttypes SET pstt_name="Instagram-Instastories" WHERE pstt_id = 3;
INSERT INTO posttypes VALUES (4, "YouTube-Videos", 4);

RENAME COLUMN userpostprices.usrpp_price TO usrpp_minprice;
ALTER TABLE userpostprices ADD usrpp_maxprice DECIMAL(10,2);
ALTER TABLE userpostprices ADD usrpp_freeofcharge SMALLINT;
UPDATE userpostprices SET usrpp_freeofcharge = 1 WHERE 1=1;
ALTER TABLE userpostprices MODIFY usrpp_freeofcharge SMALLINT NOT NULL;

INSERT INTO socialnetworks VALUES (5,"Snapchat",5);
INSERT INTO socialnetworks VALUES (6,"Pinterest",6);
INSERT INTO socialnetworks VALUES (7,"LinkedIn",7);
INSERT INTO socialnetworks VALUES (8,"Google+",8);

RENAME COLUMN usersocialnetworks.usrscl_user_id TO usrscl_usr_id;
RENAME COLUMN usersocialnetworks.usrscl_website TO usrscl_accountname;
ALTER TABLE usersocialnetworks MODIFY usrscl_accountname VARCHAR(255) NOT NULL;
ALTER TABLE usersocialnetworks ADD usrscl_comment VARCHAR(255);

ALTER TABLE socialnetworks ADD scl_img VARCHAR(32);
update socialnetworks set scl_img = "fa-instagramcolored" where scl_id = 1;
update socialnetworks set scl_img = "fa-youtubecolored" where scl_id = 2;
update socialnetworks set scl_img = "fa-facebookcolored" where scl_id = 3;
update socialnetworks set scl_img = "fa-twittercolored" where scl_id = 4;
update socialnetworks set scl_img = "fa-snapchatcolored" where scl_id = 5;
update socialnetworks set scl_img = "fa-pinterestcolored" where scl_id = 6;
update socialnetworks set scl_img = "fa-linkedincolored" where scl_id = 7;
update socialnetworks set scl_img = "fa-googlepluscolored" where scl_id = 8;
ALTER TABLE socialnetworks MODIFY scl_img VARCHAR(32) NOT NULL;

ALTER TABLE categories MODIFY ctgr_id SERIAL NOT NULL;
ALTER TABLE categories ADD CONSTRAINT  PRIMARY KEY(ctgr_id);
ALTER TABLE categories ADD CONSTRAINT UNIQUE (ctgr_name);
DELETE FROM categories WHERE ctgr_name = "Other";

ALTER TABLE brands ADD brnd_currency_id INTEGER BEFORE brnd_gender_id;
UPDATE brands SET brnd_currency_id=1 WHERE 1=1;
ALTER TABLE brands MODIFY brnd_currency_id INTEGER NOT NULL;
ALTER TABLE brands ADD CONSTRAINT FOREIGN KEY (brnd_currency_id) REFERENCES currencies(crr_id);

ALTER TABLE campaigns ADD cmp_wantedusers INTEGER BEFORE cmp_depositrequestdate;

RENAME COLUMN campaigns.cmp_post_time_day TO cmp_post_enddate;
ALTER TABLE campaigns MODIFY cmp_post_enddate DATE;
UPDATE campaigns SET cmp_post_enddate=null WHERE 1=1;

CREATE TABLE campaigncountries (
cmpcntr_id SERIAL NOT NULL PRIMARY KEY,
cmpcntr_campaign_id INTEGER NOT NULL,
cmpcntr_country_id INTEGER NOT NULL
);
CREATE TABLE campaignstates (
cmpstt_id SERIAL NOT NULL PRIMARY KEY,
cmpstt_campaigncountry_id INTEGER NOT NULL,
cmpstt_state_id INTEGER NOT NULL
);
CREATE TABLE campaigncities (
cmpcts_id SERIAL NOT NULL PRIMARY KEY,
cmpcts_campaignstate_id INTEGER NOT NULL,
cmpcts_city_id INTEGER
);

ALTER TABLE campaigncountries ADD CONSTRAINT FOREIGN KEY (cmpcntr_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaigncountries ADD CONSTRAINT FOREIGN KEY (cmpcntr_country_id) REFERENCES countries(cntr_id);
ALTER TABLE campaignstates ADD CONSTRAINT FOREIGN KEY (cmpstt_campaigncountry_id) REFERENCES campaigncountries(cmpcntr_id);
ALTER TABLE campaignstates ADD CONSTRAINT FOREIGN KEY (cmpstt_state_id) REFERENCES states(stt_id);
ALTER TABLE campaigncities ADD CONSTRAINT FOREIGN KEY (cmpcts_campaignstate_id) REFERENCES campaignstates(cmpstt_id);
ALTER TABLE campaigncities ADD CONSTRAINT FOREIGN KEY (cmpcts_city_id) REFERENCES cities(cts_id);

ALTER TABLE campaigns DROP cmp_country_id;
ALTER TABLE campaigns DROP cmp_state_id;
ALTER TABLE campaigns DROP cmp_city_id;

INSERT INTO accountstatus VALUES(7, "Stopped");

ALTER TABLE brands ADD brnd_stopdate DATETIME YEAR TO SECOND BEFORE brnd_emailvalidationdate;

RENAME COLUMN campaigns.cmp_startdate TO cmp_previewpublisheddate; --notification date for avant-premiere users
ALTER TABLE campaigns ADD cmp_publisheddate DATETIME YEAR TO SECOND BEFORE cmp_selectionstartdate; --notification date for user that are not avant-premiere
ALTER TABLE campaigns ADD cmp_selectioncomment VARCHAR(128) BEFORE cmp_actionstartdate;
ALTER TABLE campaigns DROP cmp_previewpublisheddate;

CREATE TABLE campaignuserlist ( --list of users
cmpusrl_id SERIAL NOT NULL PRIMARY KEY,
cmpusrl_campaign_id INTEGER NOT NULL,
cmpusrl_user_id INTEGER NOT NULL,
cmpusrl_visibilitydate DATE NOT NULL,
cmpusrl_previewuser SMALLINT NOT NULL, --indicates if the user is a privileged user and received the notification before other people
cmpusrl_wantedbybrand SMALLINT NOT NULL,
cmpusrl_selectionstartdate DATE NOT NULL, --user subscription start date
cmpusrl_selectionenddate DATE NOT NULL, --max date until the user can subscribe to the campaign
cmpusrl_selectioncomment VARCHAR(128),
cmpusrl_tonotify SMALLINT NOT NULL,
cmpusrl_notificationdate DATETIME YEAR TO SECOND, --user notification date
cmpusrl_isacceptbyuser SMALLINT, --1->apply, 0->reject, null->no answer
cmpusrl_useranswerdate DATETIME YEAR TO SECOND
);

ALTER TABLE campaignuserlist ADD CONSTRAINT FOREIGN KEY (cmpusrl_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignuserlist ADD CONSTRAINT FOREIGN KEY (cmpusrl_user_id) REFERENCES users(usr_id);

RENAME COLUMN users.usr_rejecteddate TO usr_stopdate;

RENAME COLUMN campaigns.cmp_suspendeddate TO cmp_pendingdate;
ALTER TABLE campaigns DROP cmp_depositrequestdate;
ALTER TABLE campaigns ADD cmp_stopdate DATETIME YEAR TO SECOND BEFORE cmp_publisheddate;
INSERT INTO campaignstatus VALUES(14,"Published");

ALTER TABLE campaigns MODIFY cmp_publisheddate DATE;
ALTER TABLE campaigns MODIFY cmp_selectionstartdate DATE;
ALTER TABLE campaigns MODIFY cmp_selectionenddate DATE;

CREATE TABLE campaignuserprices (
cmpusrp_campaign_id INTEGER NOT NULL,
cmpusrp_usr_id INTEGER NOT NULL,
cmpusrp_posttype_id INTEGER NOT NULL,
cmpusrp_price DECIMAL(10,2),
cmpusrp_freeofcharge SMALLINT NOT NULL,
PRIMARY KEY(cmpusrp_campaign_id, cmpusrp_usr_id, cmpusrp_posttype_id)
);
ALTER TABLE campaignuserprices ADD CONSTRAINT FOREIGN KEY (cmpusrp_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignuserprices ADD CONSTRAINT FOREIGN KEY (cmpusrp_usr_id) REFERENCES users(usr_id);
ALTER TABLE campaignuserprices ADD CONSTRAINT FOREIGN KEY (cmpusrp_posttype_id) REFERENCES posttypes(pstt_id);

CREATE TABLE campaignproposals (
cmpprp_id SERIAL NOT NULL PRIMARY KEY,
cmpprp_campaign_id INTEGER NOT NULL,
cmpprp_creationdate DATETIME YEAR TO SECOND,
cmpprp_submitteddate DATETIME YEAR TO SECOND,
cmpprp_validationdate DATETIME YEAR TO SECOND,
cmpprp_rejecteddate DATETIME YEAR TO SECOND,
cmpprp_status_id INTEGER NOT NULL, --draft --submitted --partially accepted --accepted --rejected
cmpprp_price DECIMAL(10,2),
cmpprp_selectioncomment VARCHAR(128),
cmpprp_islast SMALLINT NOT NULL
);

CREATE TABLE campaignproposedusers ( --list of proposed users
cmpprpu_campaignproposal_id INTEGER NOT NULL,
cmpprpu_user_id INTEGER NOT NULL,
cmpprpu_uiorder INTEGER NOT NULL,
cmpprpu_isacceptedbybrand SMALLINT, --1->accepted, 0->rejected, null->pending
cmpprpu_comment VARCHAR(128),
cmpprpu_notificationdate DATETIME YEAR TO SECOND, --user final notification date
PRIMARY KEY(cmpprpu_campaignproposal_id, cmpprpu_user_id)
);

ALTER TABLE campaignproposals ADD CONSTRAINT FOREIGN KEY (cmpprp_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignproposedusers ADD CONSTRAINT FOREIGN KEY (cmpprpu_campaignproposal_id) REFERENCES campaignproposals(cmpprp_id);
ALTER TABLE campaignproposedusers ADD CONSTRAINT FOREIGN KEY (cmpprpu_user_id) REFERENCES users(usr_id);

CREATE TABLE proposalstatus (
prp_id INTEGER NOT NULL PRIMARY KEY,
prp_name VARCHAR(32) NOT NULL
);
ALTER TABLE campaignproposals ADD CONSTRAINT FOREIGN KEY (cmpprp_status_id) REFERENCES proposalstatus(prp_id);

INSERT INTO proposalstatus VALUES (1, "Created");
INSERT INTO proposalstatus VALUES (2, "Submitted");
INSERT INTO proposalstatus VALUES (3, "Rejected");
INSERT INTO proposalstatus VALUES (4, "Validated");

ALTER TABLE campaignposttypes ADD cmppst_quantity INTEGER;
UPDATE campaignposttypes SET cmppst_quantity=1 WHERE 1=1;
ALTER TABLE campaignposttypes MODIFY cmppst_quantity INTEGER NOT NULL;

ALTER TABLE userpostprices ADD usrpp_salfatixminprice DECIMAL(10,2);
ALTER TABLE userpostprices ADD usrpp_salfatixmaxprice DECIMAL(10,2);
ALTER TABLE userpostprices ADD usrpp_salfatixfreeofcharge SMALLINT;

UPDATE userpostprices SET usrpp_salfatixfreeofcharge=0 WHERE 1=1;
ALTER TABLE userpostprices MODIFY usrpp_salfatixfreeofcharge SMALLINT NOT NULL;

ALTER TABLE userpostprices ADD usrpp_isvalidatedbysalfatix SMALLINT;
UPDATE userpostprices SET usrpp_isvalidatedbysalfatix=0 WHERE 1=1;
ALTER TABLE userpostprices MODIFY usrpp_isvalidatedbysalfatix SMALLINT NOT NULL;

ALTER TABLE userpostprices MODIFY usrpp_minprice DECIMAL(10,2) NOT NULL;
ALTER TABLE userpostprices MODIFY usrpp_maxprice DECIMAL(10,2) NOT NULL;

ALTER TABLE campaignproposedusers ADD cmpprpu_usertotalprice DECIMAL(10,2);
ALTER TABLE campaignproposedusers ADD cmpprpu_salfatixtotalprice DECIMAL(10,2);

ALTER TABLE campaigns ADD cmp_inflvalidationdate DATETIME YEAR TO SECOND BEFORE cmp_selectionstartdate;

INSERT INTO campaignstatus VALUES(15,"Influencers paid");
ALTER TABLE campaigns ADD cmp_inflpaymentdate DATETIME YEAR TO SECOND BEFORE cmp_selectionstartdate;

ALTER TABLE campaignproposedusers ADD cmpprpu_usergotproduct SMALLINT;

CREATE TABLE campaignuserposts (
cmpusrpo_id SERIAL NOT NULL PRIMARY KEY,
cmpusrpo_campaign_id INTEGER NOT NULL,
cmpusrpo_usr_id INTEGER NOT NULL,
cmpusrpo_posttype_id INTEGER NOT NULL,
cmpusrpo_ispublic SMALLINT NOT NULL,
cmpusrpo_status_id INTEGER NOT NULL,
cmpusrpo_creationdate DATETIME YEAR TO SECOND NOT NULL
);

CREATE TABLE campaignpoststatus (
cmppstst_id INTEGER NOT NULL PRIMARY KEY,
cmppstst_name VARCHAR(32) NOT NULL
);

INSERT INTO campaignpoststatus VALUES (1,"Created by influencer");
INSERT INTO campaignpoststatus VALUES (2,"Updated by influencer");
INSERT INTO campaignpoststatus VALUES (3,"Submitted to brand");
INSERT INTO campaignpoststatus VALUES (4,"Rejected by SalfatixMedia");
INSERT INTO campaignpoststatus VALUES (5,"Validated by SalfatixMedia");
INSERT INTO campaignpoststatus VALUES (6,"Validated by brand");
INSERT INTO campaignpoststatus VALUES (7,"Rejected by brand");
INSERT INTO campaignpoststatus VALUES (8,"Published by influencer");
INSERT INTO campaignpoststatus VALUES (9,"Review post privacy");
INSERT INTO campaignpoststatus VALUES (10,"Published");

CREATE TABLE campaignposts (
cmppost_id SERIAL NOT NULL PRIMARY KEY,
cmppost_campaign_id INTEGER NOT NULL,
cmppost_usr_id INTEGER NOT NULL,
cmppost_posttype_id INTEGER NOT NULL,
cmppost_url VARCHAR(255) NOT NULL,
cmppost_ispublic SMALLINT NOT NULL,
cmppost_status_id INTEGER NOT NULL,
cmppost_creationdate DATETIME YEAR TO SECOND NOT NULL
);
ALTER TABLE campaignposts ADD CONSTRAINT FOREIGN KEY (cmppost_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignposts ADD CONSTRAINT FOREIGN KEY (cmppost_usr_id) REFERENCES users(usr_id);
ALTER TABLE campaignposts ADD CONSTRAINT FOREIGN KEY (cmppost_posttype_id) REFERENCES posttypes(pstt_id);
ALTER TABLE campaignposts ADD CONSTRAINT FOREIGN KEY (cmppost_status_id) REFERENCES campaignpoststatus(cmppstst_id);

CREATE TABLE campaignpostshist (
cmpposth_id SERIAL NOT NULL PRIMARY KEY,
cmpposth_campaignpost_id INTEGER NOT NULL,
cmpposth_status_id INTEGER NOT NULL,
cmpposth_statusdate DATETIME YEAR TO SECOND NOT NULL
);
ALTER TABLE campaignpostshist ADD CONSTRAINT FOREIGN KEY (cmpposth_campaignpost_id) REFERENCES campaignposts(cmppost_id);
ALTER TABLE campaignpostshist ADD CONSTRAINT FOREIGN KEY (cmpposth_status_id) REFERENCES campaignpoststatus(cmppstst_id);

ALTER TABLE campaignposttypes ADD cmppst_tovalidate SMALLINT;
UPDATE campaignposttypes SET cmppst_tovalidate=0 WHERE 1=1;
ALTER TABLE campaignposttypes MODIFY cmppst_tovalidate SMALLINT NOT NULL;

UPDATE posttypes SET pstt_name="Instagram-Publication" WHERE pstt_id = 1;
DELETE FROM userpostprices WHERE usrpp_posttype_id = 2;
DELETE FROM campaignposttypes WHERE cmppst_posttype_id = 2;
DELETE FROM campaignuserprices WHERE cmpusrp_posttype_id = 2;
DELETE FROM campaignpostshist WHERE cmpposth_campaignpost_id IN (SELECT cmppost_id FROM campaignposts WHERE cmppost_posttype_id = 2);
DELETE FROM campaignposts WHERE cmppost_posttype_id = 2;
DELETE FROM posttypes WHERE pstt_id = 2;

INSERT INTO categories VALUES (10,"Lingerie", 10);
INSERT INTO categories VALUES (11,"DIY", 11);
INSERT INTO categories VALUES (12,"Application", 12);
INSERT INTO categories VALUES (13,"Events", 13);
INSERT INTO categories VALUES (14,"Accessories", 14);
INSERT INTO categories VALUES (15,"Health", 15);
INSERT INTO categories VALUES (16,"Home Design", 16);
INSERT INTO categories VALUES (17,"Venue", 17);

INSERT INTO socialnetworks VALUES (9,"Blog",9,"blog.png");

ALTER TABLE users ADD usr_paypal VARCHAR(128) BEFORE usr_mobile_notifications;

ALTER TABLE genders ADD gnd_uiorder INTEGER;
UPDATE genders SET gnd_uiorder = gnd_id WHERE 1=1;
ALTER TABLE genders MODIFY gnd_uiorder INTEGER NOT NULL;
DELETE FROM genders WHERE gnd_id = 4;
UPDATE genders SET gnd_name = "Male" WHERE gnd_name = "Man";
UPDATE genders SET gnd_name = "Female" WHERE gnd_name = "Woman";
ALTER TABLE genders ADD CONSTRAINT UNIQUE (gnd_name);
CREATE TABLE campaigngenders (
cmpgen_campaign_id INTEGER NOT NULL,
cmpgen_gender_id INTEGER NOT NULL,
PRIMARY KEY (cmpgen_campaign_id, cmpgen_gender_id)
);
ALTER TABLE campaigngenders ADD CONSTRAINT FOREIGN KEY (cmpgen_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaigngenders ADD CONSTRAINT FOREIGN KEY (cmpgen_gender_id) REFERENCES genders(gnd_id);
ALTER TABLE campaigns DROP cmp_gender_id;

ALTER TABLE campaignposts ADD cmppost_screenshot_post VARCHAR(255) BEFORE cmppost_creationdate;
ALTER TABLE campaignposts ADD cmppost_screenshot_stat VARCHAR(255) BEFORE cmppost_creationdate;

ALTER TABLE brandcategories ADD brndcat_isprimary SMALLINT;
UPDATE brandcategories SET brndcat_isprimary = 0 WHERE 1=1;
ALTER TABLE brandcategories MODIFY brndcat_isprimary SMALLINT NOT NULL;

CREATE TABLE brandsocialnetworks (
brndscl_id SERIAL NOT NULL PRIMARY KEY,
brndscl_brand_id INTEGER NOT NULL,
brndscl_socialnetwork_id INTEGER NOT NULL,
brndscl_accountname VARCHAR(255) NOT NULL
);
ALTER TABLE brandsocialnetworks ADD CONSTRAINT FOREIGN KEY (brndscl_brand_id) REFERENCES brands(brnd_id);
ALTER TABLE brandsocialnetworks ADD CONSTRAINT FOREIGN KEY (brndscl_socialnetwork_id) REFERENCES socialnetworks(scl_id);

ALTER TABLE brandsocialnetworks ADD brndscl_comment VARCHAR(255);

ALTER TABLE socialnetworks ADD scl_url VARCHAR(255);
UPDATE socialnetworks SET scl_url = "https://www.instagram.com/" WHERE scl_id=1;
UPDATE socialnetworks SET scl_url = "https://www.youtube.com/" WHERE scl_id=2;
UPDATE socialnetworks SET scl_url = "https://www.facebook.com/" WHERE scl_id=3;
UPDATE socialnetworks SET scl_url = "https://twitter.com/" WHERE scl_id=4;
UPDATE socialnetworks SET scl_url = "https://www.pinterest.com/" WHERE scl_id=6;
UPDATE socialnetworks SET scl_url = "https://www.linkedin.com/" WHERE scl_id=7;
UPDATE socialnetworks SET scl_url = "https://plus.google.com/" WHERE scl_id=8;


ALTER TABLE usermetrics ADD usrmtc_reach INTEGER BEFORE usrmtc_bdate;
ALTER TABLE usermetrics DROP usrmtc_socialnetwork_id;
ALTER TABLE usermetrics ADD usrmtc_usr_id INTEGER BEFORE usrmtc_instagram_userid;
ALTER TABLE usermetrics ADD CONSTRAINT FOREIGN KEY (usrmtc_usr_id) REFERENCES users(usr_id);

ALTER TABLE backofficeusers ADD bousr_stopdate DATETIME YEAR TO SECOND BEFORE bousr_lastupdatedate;

INSERT INTO accountstatus VALUES(8, "Want to leave");

INSERT INTO campaignstatus VALUES(16,"Removed");

ALTER TABLE campaignposts ADD cmppost_youtube_viewcount INTEGER;
ALTER TABLE campaignposts ADD cmppost_youtube_likecount INTEGER;
ALTER TABLE campaignposts ADD cmppost_youtube_dislikecount INTEGER;
ALTER TABLE campaignposts ADD cmppost_youtube_favoritecount INTEGER;
ALTER TABLE campaignposts ADD cmppost_youtube_commentcount INTEGER;

ALTER TABLE campaignposts ADD cmppost_ig_likes INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_comments INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_saved INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_profilevisits INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_follows INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_websiteclicks INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_discovery DECIMAL(5,2);
ALTER TABLE campaignposts ADD cmppost_ig_reach INTEGER;
ALTER TABLE campaignposts ADD cmppost_ig_impressions INTEGER;

ALTER TABLE campaignposts ADD cmppost_instastory_impressions INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_reach INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_tapsforward INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_tapsback INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_replies INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_swipeaway INTEGER;
ALTER TABLE campaignposts ADD cmppost_instastory_exists INTEGER;

CREATE TABLE campaignshist (
cmph_id SERIAL NOT NULL PRIMARY KEY,
cmph_campaign_id INTEGER NOT NULL,
cmph_campaignstatus_id INTEGER NOT NULL,
cmph_date DATETIME YEAR TO SECOND NOT NULL
);
ALTER TABLE campaignshist ADD CONSTRAINT FOREIGN KEY (cmph_campaign_id) REFERENCES campaigns(cmp_id);
ALTER TABLE campaignshist ADD CONSTRAINT FOREIGN KEY (cmph_campaignstatus_id) REFERENCES campaignstatus(cmpst_id);

ALTER TABLE campaigns DROP cmp_depositpaymentdate;
ALTER TABLE campaigns DROP cmp_totalpaymentdate;
ALTER TABLE campaigns DROP cmp_submitteddate;
ALTER TABLE campaigns DROP cmp_validationdate;
ALTER TABLE campaigns DROP cmp_deletiondate;
ALTER TABLE campaigns DROP cmp_canceldate;
ALTER TABLE campaigns DROP cmp_pendingdate;
ALTER TABLE campaigns DROP cmp_stopdate;
ALTER TABLE campaigns DROP cmp_inflpaymentdate;
ALTER TABLE campaigns DROP cmp_inflvalidationdate;

INSERT INTO campaignpoststatus VALUES (11,"Statistics requested");
INSERT INTO campaignpoststatus VALUES (12,"Statistics received");

INSERT INTO campaignstatus VALUES (17,"Statistics requested");
INSERT INTO campaignstatus VALUES (18,"Statistics received");

ALTER TABLE campaignuserlist ADD cmpusrl_usertotalprice DECIMAL(10,2);
ALTER TABLE campaignuserlist ADD cmpusrl_salfatixtotalprice DECIMAL(10,2);
UPDATE campaignuserlist SET cmpusrl_usertotalprice = 0 WHERE 1=1;
UPDATE campaignuserlist SET cmpusrl_salfatixtotalprice = 0 WHERE 1=1;
ALTER TABLE campaignuserlist MODIFY cmpusrl_usertotalprice DECIMAL(10,2) NOT NULL;
ALTER TABLE campaignuserlist MODIFY cmpusrl_salfatixtotalprice DECIMAL(10,2) NOT NULL;

CREATE TABLE params (
  par_id  SERIAL NOT NULL PRIMARY KEY,
  par_typ INTEGER NOT NULL,
  par_min DECIMAL(10,2) NOT NULL,
  par_max DECIMAL(10,2) NOT NULL,
  par_des VARCHAR(200) NOT NULL
);
INSERT INTO params VALUES (1,1,0,1,"euro-1-0.png");
INSERT INTO params VALUES (2,1,1,199,"euro-3-1.png");
INSERT INTO params VALUES (3,1,200,999,"euro-3-2.png");
INSERT INTO params VALUES (4,1,1000,99999999,"euro-3-3.png");

ALTER TABLE users ADD usr_instagram_token VARCHAR(255);

CREATE TABLE messages (
  msg_id INTEGER NOT NULL,
  msg_lang VARCHAR(8) NOT NULL,
  msg_texttitle VARCHAR(255),
  msg_textcontent LVARCHAR(4096),
  msg_htmltitle VARCHAR(255),
  msg_htmlcontent LVARCHAR(4096)
);
ALTER TABLE messages ADD CONSTRAINT PRIMARY KEY (msg_id, msg_lang) CONSTRAINT pk_messages;

EXECUTE PROCEDURE IFX_ALLOW_NEWLINE('t');

INSERT INTO messages VALUES (1,"fr","Confirmez votre inscription","Bonjour !
Vous venez de rejoindre l'agence Salfatix Media et nous vous en remercions.
Votre demande est en cours de traitement. Nous revenons vers vous au plus vite!
Merci de confirmer votre adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION#.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (1,"en","Confirm your account","Welcome,
you have successfully created an account !
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION#.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (2,"fr","Confirmez votre adresse email","Bonjour !
votre email a été mis à jour.
Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION#.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (2,"en","Confirm email address","Hello !
Your email has been updated.
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION#.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (3,"fr","Votre inscription est validée","Bonjour !
Votre compte a été validé ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi notre communauté.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (3,"en","Your account is validated","We love to have you #BRAND_NAME# !
Your account is successfully validated into Salfatix Media !
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (4,"fr","Votre inscription n'est pas validée","Bonjour !
Merci de l'intérêt que pour porter à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (4,"en","Your account is rejected","Hello !
We appreciate your interest in Salfatix Media. Unfortunately, we have the regret to decline your account registration.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (5,"fr","Campagne mise à jour","Bonjour !
Après revu par Salfatix Media, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (5,"en","Campaign updated","Hello !
after reviewing by Salfatix Media, please review the content of your campaign #CAMPAIGN_NAME#.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (6,"fr","Proposition d'influencers pour votre campagne","Bonjour !
une liste d'influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.
N'hésitez pas à la consulter et à l'éditer si nécessaire.
Merci.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (6,"en","Proposed influencers for your campaign","Hello !
A list of influencers for your campaign #CAMPAIGN_NAME# is available on our portal.
Do not hesitate to consult it and edit it if necessary.
Thank you.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (7,"fr","Valider le travail des influencers pour votre campagne","Bonjour !
le travail des influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.
N'hésitez pas à valider ou rejeter les différents travaux proposés par nos influencers.
Merci.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (7,"en","Validate influencers posts for your campaign","Hello !
influencers work for your campaign #CAMPAIGN_NAME# is available on our portal.
Feel free to validate or reject the various posts proposed by our influencers.
Thank you.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (30,"fr","Confirmez votre inscription","Bonjour #INFLUENCER_FIRSTNAME# !
Merci d'avoir rempli le formulaire pour faire partie de l'agence en tant qu' influencer.
Nous espérons collaborer avec vous très prochainement !
En attendant, suivez-nous sur #SALFATIXMEDIA_INSTAGRAM# et sur #SALFATIXMEDIA_FACEBOOK#.
Merci de confirmer votre adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION#.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (30,"en","Confirm your account","Hello #INFLUENCER_FIRSTNAME#!
Thank you for filling out the form to be part of the agency as an influencer.
We hope to collaborate with you very soon!
In the meantime, follow us on #SALFATIXMEDIA_INSTAGRAM# and #SALFATIXMEDIA_FACEBOOK#.
Please confirm your email address by clicking on the following link: #LINK_EMAIL_VALIDATION#.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (31,"fr","Confirmez votre adresse email","Bonjour #INFLUENCER_FIRSTNAME#,
votre email a été mis à jour.
Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION#.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (31,"en","Confirm email address","Hello #INFLUENCER_FIRSTNAME#!
Your email has been updated.
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION#.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (32,"fr","Votre inscription est validée","Bonjour #INFLUENCER_FIRSTNAME#!
Votre inscription est validée ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi nos Influencers de l'agence.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (32,"en","Your account is validated","Hello #INFLUENCER_FIRSTNAME#!
Your account is validated ! We thank you for your trust and we are pleased to count you among our Influencers of our agency!
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (33,"fr","Votre inscription n'est pas validée","Bonjour #INFLUENCER_FIRSTNAME#!
Merci de l'intérêt que pour porter à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription suite à certains critères non confirmes à l'agence.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (33,"en","Your account is rejected","Hello #INFLUENCER_FIRSTNAME#!
We appreciate your interest in Salfatix Media and the time you've invested i applying to be an Influencer.
Unfortunately, you have not been selected to be an Influencer with our Agency.

We encourage you to apply again when you believe your profile matches what we are looking for.

We wish you good luck with your future endeavors.

Best,

Salfatix Media",NULL,NULL);
----
INSERT INTO messages VALUES (50,"fr","Votre profil est présélectionné pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
Féliciations !! Votre profil a été présélectionné pour le deal #CAMPAIGN_NAME# !
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (50,"en","You are selected for a deal","Hello #INFLUENCER_FIRSTNAME#!
Congratulations! You have been selected for #CAMPAIGN_NAME# deal! Please proceed with the next steps.
Team @salfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (51,"fr","Votre profil n'est pas retenu pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
après étude de la sélection par la marque, votre profil n'a pas été retenu pour cette collaboration #CAMPAIGN_NAME#.
Nous vous invitons à suivre et postuler aux autres deals en cours.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (51,"en","You are not selected for a deal","Hello #INFLUENCER_FIRSTNAME#!
We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.

Unfortunately, you have not been approved to proceed with this deal.

Best,

Salfatix Media",NULL,NULL);
----
INSERT INTO messages VALUES (52,"fr","Un deal vient de démarrer","Bonjour #INFLUENCER_FIRSTNAME#!
le deal #CAMPAIGN_NAME# vient d'être lancé. Laissez libre court à votre créativité !
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (52,"en","A deal is launched","Hello #INFLUENCER_FIRSTNAME#!
#CAMPAIGN_NAME# deal bas been launched. Give free rein to your creativity!
Team @SalfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (53,"fr","Post attendu pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
nous n'avons pas encore recu l'ensemble du travail attendu pour le deal #CAMPAIGN_NAME#.
N'hésitez pas à nous contacter si vous rencontrez un problème quant à la livraison des posts.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (53,"en","Post awaited for a deal","Hello #INFLUENCER_FIRSTNAME#!
we have not received all of the expected work for the #CAMPAIGN_NAME# deal yet.
Do not hesitate to contact us if you have a problem with the delivery of posts.
Team @SalfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (54,"fr","Post non retenu pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
après étude par la marque, certains posts du deal #CAMPAIGN_NAME# ne correspondent pas aux attentes de la marque.
Une nouvelle version est attendu pour ces posts.
Vous pouvez voir la liste complète des posts en vous connectant à votre application SalfatixMedia.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (54,"en","Post rejected for a deal","Hello #INFLUENCER_FIRSTNAME#!
after study by the brand, some posts of the #CAMPAIGN_NAME# deal do not meet the expectations of the brand.
A new version is expected for these posts.
You can see the full list of posts by logging into your SalfatixMedia app.
Team @SalfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (55,"fr","Post validé pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
votre travail concernant le deal #CAMPAIGN_NAME# a été validé.
Il ne vous reste plus qu'à rendre publique l'ensemble de votre travail sur les réseaux sociaux.

La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (55,"en","Post validated for a deal","Hello #INFLUENCER_FIRSTNAME#!
your work on deal #CAMPAIGN_NAME# has been validated.
All you have to do is publicize all of your work on social networks.
Team @SalfatixMedia",NULL,NULL);
----
INSERT INTO messages VALUES (56,"fr","Statistiques attendues pour un deal","Bonjour #INFLUENCER_FIRSTNAME#!
Pouvez vous nous envoyer les statistiques de vos posts pour le deal #CAMPAIGN_NAME# ?
Merci.
La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (56,"en","Statistics awaited for a deal","Hello #INFLUENCER_FIRSTNAME#!
Can you send us the statistics of your posts for the #CAMPAIGN_NAME# deal?
Thank you.
Team @SalfatixMedia",NULL,NULL);

INSERT INTO messages VALUES (1000,"fr","Réinitialisez votre mot de passe","Bonjour !

pour réinitialiser votre mot de passe cliquez sur le lien ci-dessous:

#LINK_RESET_PASSWORD#

Si vous n'avez pas fait cette demande, merci d'ignorer cet email.

La Team @SalfatixMedia",NULL,NULL);
INSERT INTO messages VALUES (1000,"en","Reset password instructions","Hello !
to reset your password click the link below:
#LINK_RESET_PASSWORD#
If you did not request a new password, please ignore this email.

Team @SalfatixMedia",NULL,NULL);

CREATE TABLE notificationtokens (
        ntt_id   SERIAL NOT NULL PRIMARY KEY,
        ntt_usr_id INTEGER NOT NULL,
        ntt_unique_id VARCHAR(200) NOT NULL,
        ntt_device_type VARCHAR(10) NOT NULL,
        ntt_meter  INTEGER,
        ntt_token VARCHAR(200) NOT NULL);
ALTER TABLE notificationtokens ADD CONSTRAINT
                       FOREIGN KEY (ntt_usr_id)
                       REFERENCES users (usr_id)
                       CONSTRAINT fk_notificationtokens_users;
Insert Into params Values (5,2,0,0,"104718623142");
Insert Into params Values (6,2,0,0,"AAAAGGG3YaY:APA91bHmvnu6GRmn7OT_32xtCDqA1b2R_VsGJEACqjTNqJ17hhPNsfqPbTrGP9k_FvbtH3uHacUBskXwTrP8Vv2zi84KhbFWHcLmeKEeNvU-wkVJKq2OMtKftHvjCkzL1PQFJ3fT0hqoXK1m_9th-6XTo3B3q-bQOQ");

DROP TABLE campaignuserposts;
ALTER TABLE campaigns MODIFY cmp_prd_value DECIMAL(10,2);

----------------------------- 17/12/2018 ---------
UPDATE messages
SET msg_htmltitle = "Confirmez votre inscription",
    msg_htmlcontent = "Bonjour !
    <p>Vous venez de rejoindre l'agence Salfatix Media et nous vous en remercions.</p>
    <p>Votre demande est en cours de traitement. Nous revenons vers vous au plus vite!</p>
    <p>Merci de confirmer votre adresse mail en cliquant sur le lien suivant : <br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Confirm your account",
    msg_htmlcontent = "Welcome,
    <p>you have successfully created an account !</p>
    <p>Please confirm your email address by clicking on the following link : <br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Confirmez votre adresse email",
    msg_htmlcontent = "Bonjour !
    <p>votre email a été mis à jour.</p>
    <p>Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant :<br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 2 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Confirm email address",
    msg_htmlcontent = "Hello !
    <p>Your email has been updated.</p>
    <p>Please confirm your email address by clicking on the following link :<br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 2 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre inscription est validée",
    msg_htmlcontent = "Bonjour !
    <p>Votre compte a été validé ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi notre communauté.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 3 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Your account is validated",
    msg_htmlcontent = "Bonjour !
    <p>We love to have you #BRAND_NAME# !</p>
    <p>Your account is successfully validated into Salfatix Media !</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 3 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre inscription n'a pas été validée",
    msg_htmlcontent = "Bonjour !
    <p>Merci de l'intérêt que pour porter à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 4 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Your account has been rejected",
    msg_htmlcontent = "Hello !
    <p>We appreciate your interest in Salfatix Media. Unfortunately, we have the regret to decline your account registration.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 4 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Campagne mise à jour",
    msg_htmlcontent = "Bonjour !
    <p>Après revu par Salfatix Media, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 5 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Campaign updated",
    msg_htmlcontent = "Hello !
    <p>We've checked and updated your campaign as requested, please review its content #CAMPAIGN_NAME#.
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 5 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Proposition d'influencers pour votre campagne",
    msg_htmlcontent = "Bonjour !
    <p>Une liste d'influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.</p>
    <p>N'hésitez pas à la consulter et à l'éditer si nécessaire.<br /></p>
    <p>Merci.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 6 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Influencer list proposal for your campaign",
    msg_htmlcontent = "Hello !
    <p>A list of influencers for your campaign #CAMPAIGN_NAME# is available on our portal.</p>
    <p>Do not hesitate to consult it and edit it if necessary.<br /></p>
    <p>Thank you.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 6 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Valider le travail des influencers pour votre campagne",
    msg_htmlcontent = "Bonjour !
    <p>le travail des influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.</p>
    <p>N'hésitez pas à valider ou rejeter les différents travaux proposés par nos influencers.<br /></p>
    <p>Merci.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 7 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Validate influencers posts for your campaign",
    msg_htmlcontent = "Hello !
    <p>influencers work for your campaign #CAMPAIGN_NAME# is available on our portal.</p>
    <p>Feel free to validate or reject the various posts proposed by our influencers.<br /></p>
    <p>Thank you.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 7 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Confirmez votre inscription",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME# !
    <p>Merci d'avoir rempli le formulaire pour faire partie de l'agence en tant qu' influencer.</p>
    <p>Nous espérons collaborer avec vous très prochainement !</p>
    <p>En attendant, suivez-nous sur <a href=""#SALFATIXMEDIA_INSTAGRAM#"">Instagram</a> et sur <a href=""#SALFATIXMEDIA_FACEBOOK#"">Facebbok</a>.</p>
    <p>Merci de confirmer votre adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION#.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 30 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Confirm your account",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>Thank you for filling out the form to be part of the agency as an influencer.</p>
    <p>We hope to collaborate with you very soon!</p>
    <p>In the meantime, follow us on <a href=""#SALFATIXMEDIA_INSTAGRAM#"">Instagram</a> and <a href=""#SALFATIXMEDIA_FACEBOOK#"">Facebook</a>.</p>
    <p>Please confirm your email address by clicking on the following link: #LINK_EMAIL_VALIDATION#.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 30 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Confirmez votre adresse email",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#,
    <p>votre email a été mis à jour.</p>
    <p>Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant : <br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a><br />.</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 31 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Confirm email address",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>Your email has been updated.</p>
    <p>Please confirm your email address by clicking on the following link :<br />
    <a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 31 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre inscription est validée",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>Votre inscription est validée ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi nos Influencers de l'agence.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 32 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Your account is validated",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>Your account is now validated ! We thank you for your trust and we are pleased to count you among our Influencers of our agency!</p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 32 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre inscription n'a pas été acceptée",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>Merci de l'intérêt porté à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription suite à certains critères non conformes à l'agence.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 33 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Your account request has been rejected",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>We appreciate your interest in Salfatix Media and the time you've invested i applying to be an Influencer.</p>
    <p>Unfortunately, you have not been selected to be an Influencer with our Agency.<br /></p>
    <p>We encourage you to apply again when you believe your profile matches what we are looking for.<br /></p>
    <p>We wish you good luck with your future endeavors.<br /></p>
    <p>Best,<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 33 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre profil est présélectionné pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>Féliciations !! Votre profil a été présélectionné pour le deal #CAMPAIGN_NAME# !<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 50 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "You are selected for a deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>Congratulations! You have been selected for #CAMPAIGN_NAME# deal! Please proceed with the next steps.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 50 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Votre profil n'est pas retenu pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>après étude de la sélection par la marque, votre profil n'a pas été retenu pour cette collaboration #CAMPAIGN_NAME#.</p>
    <p>Nous vous invitons à suivre et postuler aux autres deals en cours.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 51 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "You are not selected for a deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.</p>
    <p>Unfortunately, you have not been approved to proceed with this deal.<br /></p>
    <p>Best,<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 51 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Un deal vient de démarrer",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>le deal #CAMPAIGN_NAME# vient d'être lancé. Laissez libre court à votre créativité !<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 52 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "A deal is launched",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>#CAMPAIGN_NAME# deal bas been launched. Give free rein to your creativity!<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 52 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Post attendu pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>nous n'avons pas encore recu l'ensemble du travail attendu pour le deal #CAMPAIGN_NAME#.</p>
    <p>N'hésitez pas à nous contacter si vous rencontrez un problème quant à la livraison des posts.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 53 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Post attendu pour un deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>we have not received all of the expected work for the #CAMPAIGN_NAME# deal yet.</p>
    <p>Do not hesitate to contact us if you have a problem with the delivery of posts.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 53 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Post non retenu pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>Après étude par la marque, certains posts du deal #CAMPAIGN_NAME# ne correspondent pas aux attentes de la marque.</p>
    <p>Une nouvelle version est attendu pour ces posts.</p>
    <p>Vous pouvez voir la liste complète des posts en vous connectant à votre application SalfatixMedia.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 54 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Post rejected for a deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>after study by the brand, some posts of the #CAMPAIGN_NAME# deal do not meet the expectations of the brand.</p>
    <p>A new version is expected for these posts.</p>
    <p>You can see the full list of posts by logging into your SalfatixMedia app.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 54 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Post validé pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>votre travail concernant le deal #CAMPAIGN_NAME# a été validé.</p>
    <p>Il ne vous reste plus qu'à rendre publique l'ensemble de votre travail sur les réseaux sociaux.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 55 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Post validated for a deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>your work on deal #CAMPAIGN_NAME# has been validated.</p>
    <p>All you have to do is publicize all of your work on social networks.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 55 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Statistiques attendues pour un deal",
    msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#!
    <p>Pouvez vous nous envoyer les statistiques de vos posts pour le deal #CAMPAIGN_NAME# ?</p>
    <p>Merci.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 56 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Statistiques attendues pour un deal",
    msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!
    <p>Can you send us the statistics of your posts for the #CAMPAIGN_NAME# deal?</p>
    <p>Thank you.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 56 AND msg_lang = "en";

UPDATE messages
SET msg_htmltitle = "Réinitialisez votre mot de passe",
    msg_htmlcontent = "Bonjour !
    <p>pour réinitialiser votre mot de passe cliquez sur le lien ci-dessous:</p>
    <p><a href=""#LINK_RESET_PASSWORD#"">#LINK_RESET_PASSWORD#</a><br /></p>
    <p>Si vous n'avez pas fait cette demande, merci d'ignorer cet email.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1000 AND msg_lang = "fr";

UPDATE messages
SET msg_htmltitle = "Réinitialisez votre mot de passe",
    msg_htmlcontent = "Hello !
    <p>To reset your password click the link below:</p>
    <p><a href=""#LINK_RESET_PASSWORD#"">#LINK_RESET_PASSWORD#</a><br /></p>
    <p>If you did not request a new password, please ignore this email.<br /></p>
    <p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p>
    <p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1000 AND msg_lang = "en";

ALTER TABLE users ADD usr_email_style CHAR(1) BEFORE usr_currency_id;
ALTER TABLE users ADD usr_notif_style CHAR(1) BEFORE usr_email_notifications;
UPDATE users SET usr_email_style = "H";
UPDATE users SET usr_notif_style = "T";
ALTER TABLE backofficeusers ADD bousr_email_style CHAR(1) BEFORE bousr_country_id;
UPDATE backofficeusers SET bousr_email_style = "H";
ALTER TABLE brands ADD brnd_email_style CHAR(1) BEFORE brnd_password;
UPDATE brands SET brnd_email_style = "H";

UPDATE messages SET msg_htmltitle = "Statistics awaited for a deal" WHERE msg_id = 56 and msg_lang = "en";

ALTER TABLE campaigns ADD cmp_issharedonfacebook SMALLINT BEFORE cmp_post_guidelines;
UPDATE campaigns SET cmp_issharedonfacebook=0 WHERE 1=1;
ALTER TABLE campaigns MODIFY cmp_issharedonfacebook SMALLINT NOT NULL;

ALTER TABLE campaigns ADD cmp_sharedfacebooklink VARCHAR(255) BEFORE cmp_post_guidelines;
ALTER TABLE brands ADD brnd_address_number VARCHAR(16) BEFORE brnd_currency_id,
                   ADD brnd_address_street VARCHAR(128) BEFORE brnd_currency_id,
                   ADD brnd_address_zipcode VARCHAR(128) BEFORE brnd_currency_id,
                   ADD brnd_address_town VARCHAR(128) BEFORE brnd_currency_id,
                   ADD brnd_address_more VARCHAR(128) BEFORE brnd_currency_id;

ALTER TABLE states MODIFY stt_name VARCHAR(60) NOT NULL;
ALTER TABLE cities MODIFY cts_name VARCHAR(60) NOT NULL;

ALTER TABLE brands ADD brnd_contact_rank VARCHAR(128) BEFORE brnd_email;

Insert into cities values (334823,"La Plaine-Saint-Denis",953);

create temp table tmpbrands (
brnd_id INTEGER,
brnd_pic_id INTEGER,
brnd_name VARCHAR(128),
brnd_website VARCHAR(255),
brnd_country_id INTEGER,
brnd_state_id INTEGER,
brnd_city_id INTEGER,
brnd_address_number VARCHAR(16),
brnd_address_street VARCHAR(128),
brnd_address_zipcode VARCHAR(128),
brnd_address_town VARCHAR(128),
brnd_address_more VARCHAR(128),
brnd_currency_id INTEGER,
brnd_gender_id INTEGER,
brnd_firstname VARCHAR(128),
brnd_lastname VARCHAR(128),
brnd_contact_rank VARCHAR(128),
brnd_email VARCHAR(128),
brnd_email_style CHAR(1),
brnd_password VARCHAR(255),
brnd_mobile_phonenumber BIGINT,
brnd_accountstatus_id INTEGER,
brnd_createdby_id INTEGER,
brnd_creationdate DATETIME YEAR TO SECOND,
brnd_deletiondate DATETIME YEAR TO SECOND,
brnd_validationdate DATETIME YEAR TO SECOND,
brnd_canceldate DATETIME YEAR TO SECOND,
brnd_suspendeddate DATETIME YEAR TO SECOND,
brnd_stopdate DATETIME YEAR TO SECOND,
brnd_emailvalidationdate DATETIME YEAR TO SECOND,
brnd_lastupdatedate DATETIME YEAR TO SECOND,
brnd_lastlogindate DATETIME YEAR TO SECOND);
insert into tmpbrands select * from brands;
update tmpbrands set brnd_id = brnd_id+200;
insert into brands select * from tmpbrands;
update brandcategories set brndcat_brand_id = brndcat_brand_id+200;
update brandsocialnetworks set brndscl_brand_id = brndscl_brand_id+200;
update campaigns set cmp_brand_id = cmp_brand_id+200;
delete from brands where brnd_id < 200;
drop table tmpbrands;

Insert into brands values (1,1,"Brand-A","www.4js.com",75,953,74133,"55","Rue du Faubourg Saint Honoré","75000","","",1,2,"Jean","Tenrien","Head of development","testa@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);
Insert into brands values (2,1,"Brand-B","www.fourjs.com",75,953,74133,"40B","Avenue de Suffren","75015","","",1,3,"Jeanne","Denfer","CEO","testb@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);

Alter table categories Add ctgr_parent Integer;
Update categories set ctgr_parent = 1 where ctgr_id = 10;
Update categories set ctgr_parent = 1 where ctgr_id = 14;
INSERT INTO categories VALUES (18,"Designer", 18,1);
INSERT INTO categories VALUES (19,"Jewelry", 19, 1);
INSERT INTO categories VALUES (20,"Purse", 20, 1);
INSERT INTO categories VALUES (21,"Shoes", 21, 1);
INSERT INTO categories VALUES (22,"Sportswear", 22, 1);
Update categories set ctgr_parent = 2 where ctgr_id = 15;
INSERT INTO categories VALUES (23,"Yoga", 23, 1);
INSERT INTO categories VALUES (24,"Parfumes", 24, 3);
Update categories set ctgr_parent = 9 where ctgr_id = 12;
Update categories set ctgr_parent = 13 where ctgr_id = 17;
INSERT INTO categories VALUES (25,"Home", 25, Null);
Update categories set ctgr_parent = 25 where ctgr_id = 16;
INSERT INTO categories VALUES (26,"Hotel", 26, 25);
INSERT INTO categories VALUES (27,"Agency", 27, Null);
INSERT INTO categories VALUES (28,"Advertising agencies", 28, 27);
INSERT INTO categories VALUES (29,"Magazine", 29, 27);
INSERT INTO categories VALUES (30,"Model agency", 30, 27);
INSERT INTO categories VALUES (31,"Photo production", 31, 27);
INSERT INTO categories VALUES (32,"Services", 32, 27);
INSERT INTO categories VALUES (33,"Start up", 33, 27);
INSERT INTO categories VALUES (34,"Talent agency", 34, 27);
INSERT INTO categories VALUES (35,"Stylist agency", 35, 27);
INSERT INTO categories VALUES (36,"Glasses", 36, 1);
INSERT INTO categories VALUES (37,"Hats", 37, 1);
INSERT INTO categories VALUES (38,"Celebrity agency", 38,27);

Insert into brandcategories values (1,32,0);
Insert into brandcategories values (2,28,0);

Insert into brandsocialnetworks values (0,1,3,"Brand-A",NULL);
Insert into brandsocialnetworks values (0,1,9,"https://www.4js.com",Null);

UPDATE socialnetworks SET scl_url = "https://www.youtube.com/user/" WHERE scl_id=2;
UPDATE socialnetworks SET scl_name = "Youtube User" WHERE scl_id=2;
Insert into socialnetworks Values (10,"Youtube Channel",10,"fa-youtubecolored","https://www.youtube.com/channel/");

RENAME COLUMN categories.ctgr_parent TO ctgr_parent_id;

UPDATE socialnetworks SET scl_url = "https://www.linkedin.com/in/" WHERE scl_id=7;
UPDATE socialnetworks SET scl_url = "https://plus.google.com/+" WHERE scl_id=8;

-- Add Influencers --
Insert into cities values (334824,"Atlanta",3435);
Insert into cities values (334825,"Bellevue",3472);
Insert into cities values (334826,"Seattle",3472);
Insert into cities values (334827,"Boston",3446);
update cities set cts_state_id = 3434 where cts_id >= 319567 and cts_id <= 319633 and cts_state_id = 2438;
update cities set cts_state_id = 3435 where cts_id >= 320442 and cts_id <= 320464 and cts_state_id = 1594;
update cities set cts_state_id = 3451 where cts_id >= 320850 and cts_id <= 320905 and cts_state_id = 415;
update cities set cts_state_id = 3487 where cts_id >= 322517 and cts_id <= 322528 and cts_state_id = 165;
update cities set cts_state_id = 3491 where cts_id >= 322557 and cts_id <= 322563 and cts_state_id = 672;
update cities set cts_state_id = 3522 where cts_id >= 322894 and cts_id <= 322904 and cts_state_id = 634;
update cities set cts_state_id = 3536 where cts_id >= 323066 and cts_id <= 323080 and cts_state_id = 657;
Insert into cities values (334828,"Chicago",3438);
Insert into cities values (334829,"Irvine",3429);
Insert into cities values (334830,"Fort Lee",3455);
Insert into cities values (334831,"Marietta",3435);
Insert into cities values (334832,"San José",3429);
Insert into cities values (334833,"Santa Monica",3429);
Insert into cities values (334834,"Santa Ana",3429);
Insert into cities values (334835,"Stoneham",3446);
Insert into cities values (334836,"Cambridge",3446);
Insert into cities values (334837,"Valley Glen",3429);

UPDATE messages
SET msg_htmlcontent = "Bonjour !<p>Vous venez de rejoindre l'agence Salfatix Media et nous vous en remercions.</p><p>Votre demande est en cours de traitement. Nous revenons vers vous au plus vite!</p><p>Merci de confirmer votre adresse mail en cliquant <a href=""#LINK_EMAIL_VALIDATION#"">ici</a>.</p><br /><p>Si ce lien ne fonctionne pas, veuillez copier le lien suivant et le coller dans votre navigateur préféré :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1 AND msg_lang = "fr";
UPDATE messages
SET msg_htmlcontent = "Welcome,<p>you have successfully created an account !</p><p>Please confirm your email address by clicking <a href=""#LINK_EMAIL_VALIDATION#"">here</a>.</p><br /><p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1 AND msg_lang = "en";
UPDATE messages
SET msg_htmlcontent = "Bonjour !<p>votre email a été mis à jour.</p><p>Merci de confirmer votre nouvelle adresse mail en cliquant <a href=""#LINK_EMAIL_VALIDATION#"">ici</a>.</p><br /><p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 2 AND msg_lang = "fr";
UPDATE messages
SET msg_htmlcontent = "Hello !<p>Your email has been updated.</p><p>Please confirm your email address by clicking <a href=""#LINK_EMAIL_VALIDATION#"">here</a>.</p><br /><p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 2 AND msg_lang = "en";
UPDATE messages
SET msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME# !<p>Merci d'avoir rempli le formulaire pour faire partie de l'agence en tant qu' influencer.</p><p>Nous espérons collaborer avec vous très prochainement !</p><p>En attendant, suivez-nous sur <a href=""#SALFATIXMEDIA_INSTAGRAM#"">Instagram</a> et sur <a href=""#SALFATIXMEDIA_FACEBOOK#"">Facebbok</a>.</p><p>Merci de confirmer votre adresse mail en cliquant <a href=""#LINK_EMAIL_VALIDATION#"">ici</a>.</p><br /><p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 30 AND msg_lang = "fr";
UPDATE messages
SET msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!<p>Thank you for filling out the form to be part of the agency as an influencer.</p><p>We hope to collaborate with you very soon!</p><p>In the meantime, follow us on <a href=""#SALFATIXMEDIA_INSTAGRAM#"">Instagram</a> and <a href=""#SALFATIXMEDIA_FACEBOOK#"">Facebook</a>.</p><p>Please confirm your email address by clicking <a href=""#LINK_EMAIL_VALIDATION#"">here</a>.</p><br /><p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 30 AND msg_lang = "en";
UPDATE messages
SET msg_htmlcontent = "Bonjour #INFLUENCER_FIRSTNAME#,<p>votre email a été mis à jour.</p><p>Merci de confirmer votre nouvelle adresse mail en cliquant <a href=""#LINK_EMAIL_VALIDATION#"">ici</a>.</p><br /><p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.<br></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 31 AND msg_lang = "fr";
UPDATE messages
SET msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!<p>Your email has been updated.</p><p>Please confirm your email address by clicking <a href=""#LINK_EMAIL_VALIDATION#"">here</a>.</p><br /><p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br /><a href=""#LINK_EMAIL_VALIDATION#"">#LINK_EMAIL_VALIDATION#</a>.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 31 AND msg_lang = "en";
UPDATE messages
SET msg_htmlcontent = "Hello #INFLUENCER_FIRSTNAME#!<p>your work on deal #CAMPAIGN_NAME# has been validated.</p><p>All you have to do is to make public all of your work on social networks.<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 55 AND msg_lang = "en";
UPDATE messages
SET msg_htmlcontent = "Bonjour !<p>pour réinitialiser votre mot de passe cliquez <a href=""#LINK_RESET_PASSWORD#"">ici</a>.</p><br /><p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br /><p><a href=""#LINK_RESET_PASSWORD#"">#LINK_RESET_PASSWORD#</a><br /></p><br /><p>Si vous n'avez pas fait cette demande, merci d'ignorer cet email.<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1000 AND msg_lang = "fr";
UPDATE messages
SET msg_htmlcontent = "Hello !<p>To reset your password click <a href=""#LINK_RESET_PASSWORD#"">here</a>.</p><br /><p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br /><a href=""#LINK_RESET_PASSWORD#"">#LINK_RESET_PASSWORD#</a><br /></p><p>If you did not request a new password, please ignore this email.<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>"
WHERE msg_id = 1000 AND msg_lang = "en";

ALTER TABLE campaigns ADD cmp_isproductneeded SMALLINT BEFORE cmp_prd_description;
UPDATE campaigns SET cmp_isproductneeded=1 WHERE 1=1;
ALTER TABLE campaigns MODIFY cmp_isproductneeded SMALLINT NOT NULL;

DELETE FROM brandcategories;
Insert into brandcategories values (1,32,1);
Insert into brandcategories values (2,28,1);
Insert into brandcategories values (2,34,0);

INSERT INTO messages VALUES (57,"fr","Campagne acceptée","Bonjour !\n\nVotre campagne #CAMPAIGN_NAME# a été retenue et nous sommes d'ors et déjà au travail.\nNous reviendrons vers vous sous peu pour discuter de la suite des opérations.\nLa Team @SalfatixMedia\n","Campagne acceptée","Bonjour !<p>Votre campagne #CAMPAIGN_NAME# a été retenue et nous sommes d'ors et déjà au travail.</p><p>Nous reviendrons vers vous sous peu pour discuter de la suite des opérations.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>");
INSERT INTO messages VALUES (57,"en","Campaign approved","Hello !\n\nYour campaign #CAMPAIGN_NAME# has caught our attention. We are already working on it\nWe will shortly come back to you to discuss next steps to take.\n\nTeam @salfatixMedia\n","Campaign approved","Hello !<p>Your campaign #CAMPAIGN_NAME# has caught our attention. We are already working on it.</p><p>We will shortly come back to you to discuss next steps to take.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>");

UPDATE messages SET msg_textcontent = "Bonjour !\n\nSuite à notre révision, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.\n\nLa Team @SalfatixMedia\n", msg_htmlcontent = "Bonjour !<p>Suite à notre révision, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>" WHERE msg_id = 5 AND msg_lang = "fr";
UPDATE messages SET msg_textcontent = "Hello !\n\nWe've reviewed your campaign proposal, please check the content of your campaign #CAMPAIGN_NAME# and let us know if it sweets to you.\n\nTeam @salfatixMedia\n", msg_htmlcontent = "Hello !<p>We've checked and updated your campaign as requested, please review its content #CAMPAIGN_NAME#.</p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>" WHERE msg_id = 5 AND msg_lang = "en";

ALTER TABLE campaignuserlist ADD cmpusrl_userwantedprice DECIMAL(10,2);
ALTER TABLE campaignuserlist ADD cmpusrl_uiorder INTEGER;
ALTER TABLE campaignuserlist ADD cmpusrl_isacceptedbysalfatix SMALLINT;
ALTER TABLE campaignuserlist ADD cmpusrl_isacceptedbybrand SMALLINT;
ALTER TABLE campaignuserlist ADD cmpusrl_commentforbrand VARCHAR(128);
ALTER TABLE campaignuserlist ADD cmpusrl_usergotproduct SMALLINT;
ALTER TABLE campaignuserlist ADD cmpusrl_isuserpaid SMALLINT;
ALTER TABLE campaignuserlist ADD cmpusrl_userpaid DECIMAL(10,2);

ALTER TABLE campaignposts ADD cmppost_isacceptedbysalfatix SMALLINT;
ALTER TABLE campaignposts ADD cmppost_isacceptedbybrand SMALLINT;
ALTER TABLE campaignposts ADD cmppost_filename VARCHAR(255);
ALTER TABLE campaignposts ADD cmppost_postno SMALLINT;
ALTER TABLE campaignposts ADD cmppost_uiorder SMALLINT;
ALTER TABLE campaignposts MODIFY (cmppost_url VARCHAR(255));
ALTER TABLE campaignposts MODIFY (cmppost_ispublic SMALLINT);

DROP TABLE campaignproposedusers;
DROP TABLE campaignproposals;
DROP TABLE proposalstatus;

EXECUTE PROCEDURE IFX_ALLOW_NEWLINE('t');

INSERT INTO messages VALUES (58,"fr","Nouvelle offre pour un deal"
,"Bonjour #INFLUENCER_FIRSTNAME#!

Nous apprécions votre intérêt pour la campagne #CAMPAIGN_NAME# et le temps investi à la séléctionner.
Malheureusement, votre proposition de prix n'a pas été acceptée. Nous vous avons envoyé une nouvelle proposition.
N'hésitez pas vérifier et valider cette nouvelle proposition si elle vous convient.

La Team @SalfatixMedia"
,"Nouvelle offre pour un deal"
,"Bonjour #INFLUENCER_FIRSTNAME#!<p>Nous apprécions votre intérêt pour la campagne #CAMPAIGN_NAME# et le temps investi à la séléctionner.</p><p>Malheureusement, votre proposition de prix n'a pas été acceptée. Nous vous avons envoyé une nouvelle proposition.<br />N'hésitez pas vérifier et valider cette nouvelle proposition si elle vous convient.<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">La Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>");


INSERT INTO messages VALUES (58,"en","New proposal for a deal"
,"Hello #INFLUENCER_FIRSTNAME#!

We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applying to take part in the deal with the Brand.

Unfortunately, the price you've proposed has not been accepted. We've resent you this deal with a new proposal.
Do not hesitate to check and apply to the deal #CAMPAIGN_NAME# if that new proposal suites you.

Best,

Salfatix Media"
,"New proposal for a deal"
,"Hello #INFLUENCER_FIRSTNAME#!<p>We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applying to take part in the deal with the Brand.</p><p>Unfortunately, the price you've proposed has not been accepted. We've resent you this deal with a new proposal.<br />Do not hesitate to check and apply to the deal #CAMPAIGN_NAME# if that new proposal suites you.<br /></p><p>Best,<br /></p><p><img src=""#LINK_SIGNATURE_LOGO#"" alt="""" width=""51"" height=""49"" align=""middle"">The Team Salfatix Media<br /></p><p><a href=""#SALFATIXMEDIA_INSTAGRAM#"">@SalfatixMedia</a><a href=""#SALFATIXMEDIA_WWW#"" target=""_blank""><br>www.salfatixmedia.com</a></p>");


ALTER TABLE campaignposts ADD cmppost_onlinedate DATETIME YEAR TO SECOND BEFORE cmppost_youtube_viewcount;
ALTER TABLE campaignposts ADD cmppost_lastmetricsdate DATETIME YEAR TO SECOND BEFORE cmppost_youtube_viewcount;