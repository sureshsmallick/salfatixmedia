--IMPORT FGL insertdbcountries
--IMPORT FGL insertstates
--IMPORT FGL insertcities1
--IMPORT FGL insertcities2
--IMPORT FGL insertcities3
--IMPORT FGL insertcities4
--IMPORT FGL insertcities5
--IMPORT FGL insertcities6
--IMPORT FGL insertcities7
--IMPORT FGL insertcities8
--IMPORT FGL insertcities9
--IMPORT FGL insertcities10
--IMPORT FGL insertcities11
--IMPORT FGL insertcities12
IMPORT FGL load_pics

Function db_add_values()
  DEFINE s,s1 STRING

  Insert Into params Values (1,1,0,1,"euro-1-0.png");
  Insert Into params Values (2,1,1,199,"euro-3-1.png");
  Insert Into params Values (3,1,200,999,"euro-3-2.png");
  Insert Into params Values (4,1,1000,99999999,"euro-3-3.png");
  Insert Into params Values (5,2,0,0,"104718623142");
  Insert Into params Values (6,2,0,0,"AAAAGGG3YaY:APA91bHmvnu6GRmn7OT_32xtCDqA1b2R_VsGJEACqjTNqJ17hhPNsfqPbTrGP9k_FvbtH3uHacUBskXwTrP8Vv2zi84KhbFWHcLmeKEeNvU-wkVJKq2OMtKftHvjCkzL1PQFJ3fT0hqoXK1m_9th-6XTo3B3q-bQOQ");

  INSERT INTO genders VALUES (1,"Not specified",1);
  INSERT INTO genders VALUES (2,"Male",2);
  INSERT INTO genders VALUES (3,"Female",3);

  INSERT INTO categories VALUES (1,"Fashion",1,NULL);
  INSERT INTO categories VALUES (2,"Fitness",2,NULL);
  INSERT INTO categories VALUES (3,"Beauty",3,NULL);
  INSERT INTO categories VALUES (4,"Swimwear",4,NULL);
  INSERT INTO categories VALUES (5,"Luxury",5,NULL);
  INSERT INTO categories VALUES (6,"Travel",6,NULL);
  INSERT INTO categories VALUES (7,"Food",7,NULL);
  INSERT INTO categories VALUES (8,"Music",8,NULL);
  INSERT INTO categories VALUES (9,"Tech",9,NULL);
  INSERT INTO categories VALUES (10,"Lingerie", 10,1);
  INSERT INTO categories VALUES (11,"DIY", 11,NULL);
  INSERT INTO categories VALUES (12,"Application", 12,9);
  INSERT INTO categories VALUES (13,"Events", 13,NULL);
  INSERT INTO categories VALUES (14,"Accessories", 14,1);
  INSERT INTO categories VALUES (15,"Health", 15, 2);
  INSERT INTO categories VALUES (16,"Home Design", 16,25);
  INSERT INTO categories VALUES (17,"Venue", 17,13);
  INSERT INTO categories VALUES (18,"Designer", 18,1);
  INSERT INTO categories VALUES (19,"Jewelry", 19, 1);
  INSERT INTO categories VALUES (20,"Purse", 20, 1);
  INSERT INTO categories VALUES (21,"Shoes", 21, 1);
  INSERT INTO categories VALUES (22,"Sportswear", 22, 1);
  INSERT INTO categories VALUES (23,"Yoga", 23, 1);
  INSERT INTO categories VALUES (24,"Parfumes", 24, 3);
  INSERT INTO categories VALUES (25,"Home", 25, Null);
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

  INSERT INTO currencies VALUES (1, "Euro", "€");

  INSERT INTO createdby VALUES (1, "Brand");
  INSERT INTO createdby VALUES (2, "SalfatixMedia");
  INSERT INTO createdby VALUES (3, "Brand helped by SalfatixMedia");
  INSERT INTO createdby VALUES (4, "Influencer");

  INSERT INTO accountstatus VALUES(1,"Completed");
  INSERT INTO accountstatus VALUES(2,"Cancelled");
  INSERT INTO accountstatus VALUES(3,"Incomplete");
  INSERT INTO accountstatus VALUES(4,"Validated");
  INSERT INTO accountstatus VALUES(5,"Suspended");
  INSERT INTO accountstatus VALUES(6,"Deleted");
  INSERT INTO accountstatus VALUES(7,"Stopped");
  INSERT INTO accountstatus VALUES(8,"Want to leave");

  INSERT INTO campaignstatus VALUES(1,"Created");
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
  INSERT INTO campaignstatus VALUES(13,"Pending");
  INSERT INTO campaignstatus VALUES(14,"Published");
  INSERT INTO campaignstatus VALUES(15,"Influencers paid");
  INSERT INTO campaignstatus VALUES(16,"Removed");
  INSERT INTO campaignstatus VALUES (17,"Statistics requested");
  INSERT INTO campaignstatus VALUES (18,"Statistics received");

  INSERT INTO posttypes VALUES (1,"Instagram-Publication",1);
  INSERT INTO posttypes VALUES (3,"Instagram-Instastories",3);
  INSERT INTO posttypes VALUES (4,"Youtube-Videos",4);

  INSERT INTO postdurations VALUES (1, "1 Month");
  INSERT INTO postdurations VALUES (2, "1 Day");
  INSERT INTO postdurations VALUES (3, "1 Week");
  INSERT INTO postdurations VALUES (4, "Permanent");

  INSERT INTO tagtypes VALUES (1, "Hashtag");
  INSERT INTO tagtypes VALUES (2, "Usertag");

  INSERT INTO socialnetworks VALUES (1, "Instagram",1,"fa-instagramcolored","https://www.instagram.com/");
  INSERT INTO socialnetworks VALUES (2, "Youtube User",2,"fa-youtubecolored","https://www.youtube.com/user/");
  INSERT INTO socialnetworks VALUES (3, "Facebook",3,"fa-facebookcolored","https://www.facebook.com/");
  INSERT INTO socialnetworks VALUES (4, "Twitter",4,"fa-twittercolored","https://twitter.com/");
  INSERT INTO socialnetworks VALUES (5,"Snapchat",5,"fa-snapchatcolored",NULL);
  INSERT INTO socialnetworks VALUES (6,"Pinterest",6,"fa-pinterestcolored","https://www.pinterest.com/");
  INSERT INTO socialnetworks VALUES (7,"LinkedIn",7,"fa-linkedincolored","https://www.linkedin.com/");
  INSERT INTO socialnetworks VALUES (8,"Google+",8,"fa-googlepluscolored","https://plus.google.com/");
  INSERT INTO socialnetworks VALUES (9,"Blog",9,"blog.png",NULL);
  Insert into socialnetworks Values (10,"Youtube Channel",10,"fa-youtubecolored","https://www.youtube.com/channel/");

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

  INSERT INTO proposalstatus VALUES (1, "Created");
  INSERT INTO proposalstatus VALUES (2, "Submitted");
  INSERT INTO proposalstatus VALUES (3, "Rejected");
  INSERT INTO proposalstatus VALUES (4, "Validated");

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
  INSERT INTO campaignpoststatus VALUES (11,"Statistics requested");
  INSERT INTO campaignpoststatus VALUES (12,"Statistics received");

---- Start Mails
LET s = "Bonjour !\n
\n
Vous venez de rejoindre l'agence Salfatix Media et nous vous en remercions.\n
Votre demande est en cours de traitement. Nous revenons vers vous au plus vite!\n
\n
Merci de confirmer votre adresse mail en cliquant sur le lien suivant : \n
#LINK_EMAIL_VALIDATION#\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
         "<p>Vous venez de rejoindre l'agence Salfatix Media et nous vous en remercions.</p>"||
         "<p>Votre demande est en cours de traitement. Nous revenons vers vous au plus vite!</p>"||
         "<p>Merci de confirmer votre adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>"||
         "<br />"||
         "<p>Si ce lien ne fonctionne pas, veuillez copier le lien suivant et le coller dans votre navigateur préféré :<br />"||
         "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br /></p>"||
         "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
         "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (1,"fr","Confirmez votre inscription",s,"Confirmez votre inscription",s1);
LET s = "Welcome,\n
\n
you have successfully created an account !\n
\n
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION# .\n
\n
Team @salfatixMedia\n"
LET s1 = "Welcome,"||
    "<p>you have successfully created an account !</p>"||
    "<p>Please confirm your email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>"||
    "<br />"||
    "<p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (1,"en","Confirm your account",s,"Confirm your account",s1);
----
LET s = "Bonjour !\n
\n
votre email a été mis à jour.\n
\n
Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION# .\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>votre email a été mis à jour.</p>"||
    "<p>Merci de confirmer votre nouvelle adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>"||
    "<br />"||
    "<p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (2,"fr","Confirmez votre adresse email",s,"Confirmez votre adresse email",s1);
LET s = "Hello !\n
\n
Your email has been updated.\n
\n
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION# .\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>Your email has been updated.</p>"||
    "<p>Please confirm your email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>"||
    "<br />"||
    "<p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (2,"en","Confirm email address",s,"Confirm email address",s1);
----
LET s = "Bonjour !\n
\n
Votre compte a été validé !\n
Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi notre communauté.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>Votre compte a été validé ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi notre communauté.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (3,"fr","Votre inscription est validée",s,"Votre inscription est validée",s1);
LET s = "We love to have you #BRAND_NAME# !\n
\n
Your account is successfully validated into Salfatix Media !\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>We love to have you #BRAND_NAME# !</p>"||
    "<p>Your account is successfully validated into Salfatix Media !</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (3,"en","Your account is validated",s,"Your account is validated",s1);
----
LET s = "Bonjour !\n
\n
Merci de l'intérêt que pour porter à notre agence.\n
Nous sommes cependant au regret de décliner votre demande d'inscription.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>Merci de l'intérêt que pour porter à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (4,"fr","Votre inscription n'est pas validée",s,"Votre inscription n'est pas validée",s1);
LET s = "Hello !\n
\n
We appreciate your interest in Salfatix Media.\n
Unfortunately, we have the regret to decline your account registration.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>We appreciate your interest in Salfatix Media. Unfortunately, we have the regret to decline your account registration.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (4,"en","Your account is rejected",s,"Your account is rejected",s1);
----
LET s = "Bonjour !\n
\n
Suite à notre révision, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>Après revu par Salfatix Media, merci de revoir le contenu de votre campagne #CAMPAIGN_NAME#.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (5,"fr","Campagne mise à jour",s,"Campagne mise à jour",s1);
LET s = "Hello !\n
\n
We've reviewed your campaign proposal, please check the content of your campaign #CAMPAIGN_NAME# and let us know if it sweets to you.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>We've checked and updated your campaign as requested, please review its content #CAMPAIGN_NAME#.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (5,"en","Campaign updated",s,"Campaign updated",s1);
----
LET s = "Bonjour !\n
\n
une liste d'influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.\n
N'hésitez pas à la consulter et à l'éditer si nécessaire.\n
Merci.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>Une liste d'influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.</p>"||
    "<p>N'hésitez pas à la consulter et à l'éditer si nécessaire.<br /></p>"||
    "<p>Merci.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (6,"fr","Proposition d'influencers pour votre campagne",s,"Proposition d'influencers pour votre campagne",s1);
LET s = "Hello !\n
\n
A list of influencers for your campaign #CAMPAIGN_NAME# is available on our portal.\n
Do not hesitate to consult it and edit it if necessary.\n
Thank you.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>A list of influencers for your campaign #CAMPAIGN_NAME# is available on our portal.</p>"||
    "<p>Do not hesitate to consult it and edit it if necessary.<br /></p>"||
    "<p>Thank you.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (6,"en","Proposed influencers for your campaign",s,"Proposed influencers for your campaign",s1);
----
LET s = "Bonjour !\n
\n
le travail des influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.\n
N'hésitez pas à valider ou rejeter les différents travaux proposés par nos influencers.\n
Merci.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>le travail des influencers pour votre campagne #CAMPAIGN_NAME# est disponible sur notre portail.</p>"||
    "<p>N'hésitez pas à valider ou rejeter les différents travaux proposés par nos influencers.<br /></p>"||
    "<p>Merci.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (7,"fr","Validez le travail des influencers pour votre campagne",s,"Validez le travail des influencers pour votre campagne",s1);
LET s = "Hello !\n
\n
influencers work for your campaign #CAMPAIGN_NAME# is available on our portal.\n
Feel free to validate or reject the various posts proposed by our influencers.\n
Thank you.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>influencers work for your campaign #CAMPAIGN_NAME# is available on our portal.</p>"||
    "<p>Feel free to validate or reject the various posts proposed by our influencers.<br /></p>"||
    "<p>Thank you.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (7,"en","Validate influencers posts for your campaign",s,"Validate influencers posts for your campaign",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME# !\n
\n
Merci d'avoir rempli le formulaire pour faire partie de l'agence en tant qu' influencer.\n
Nous espérons collaborer avec vous très prochainement !\n
En attendant, suivez-nous sur #SALFATIXMEDIA_INSTAGRAM# et sur #SALFATIXMEDIA_FACEBOOK# .\n
\n
Merci de confirmer votre adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION# .\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME# !"||
    "<p>Merci d'avoir rempli le formulaire pour faire partie de l'agence en tant qu' influencer.</p>"||
    "<p>Nous espérons collaborer avec vous très prochainement !</p>"||
    "<p>En attendant, suivez-nous sur <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">Instagram</a> et sur <a href=\"#SALFATIXMEDIA_FACEBOOK#\">Facebbok</a>.</p>"||
    "<p>Merci de confirmer votre adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>"||
    "<br />"||
    "<p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (30,"fr","Confirmez votre inscription",s,"Confirmez votre inscription",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
Thank you for filling out the form to be part of the agency as an influencer.\n
We hope to collaborate with you very soon!\n
In the meantime, follow us on #SALFATIXMEDIA_INSTAGRAM# and #SALFATIXMEDIA_FACEBOOK# .\n
\n
Please confirm your email address by clicking on the following link: #LINK_EMAIL_VALIDATION# .\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>Thank you for filling out the form to be part of the agency as an influencer.</p>"||
    "<p>We hope to collaborate with you very soon!</p>"||
    "<p>In the meantime, follow us on <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">Instagram</a> and <a href=\"#SALFATIXMEDIA_FACEBOOK#\">Facebook</a>.</p>"||
    "<p>Please confirm your email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>"||
    "<br />"||
    "<p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (30,"en","Confirm your account",s,"Confirm your account",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#,\n
\n
votre email a été mis à jour.\n
\n
Merci de confirmer votre nouvelle adresse mail en cliquant sur le lien suivant : #LINK_EMAIL_VALIDATION# .\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#,"||
    "<p>votre email a été mis à jour.</p>"||
    "<p>Merci de confirmer votre nouvelle adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>"||
    "<br />"||
    "<p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (31,"fr","Confirmez votre adresse email",s,"Confirmez votre adresse email",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
Your email has been updated.\n
\n
Please confirm your email address by clicking on the following link : #LINK_EMAIL_VALIDATION# .\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>Your email has been updated.</p>"||
    "<p>Please confirm your email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>"||
    "<br />"||
    "<p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br />"||
    "<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (31,"en","Confirm email address",s,"Confirm email address",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
Votre inscription est validée !\n
Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi nos Influencers de l'agence.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Votre inscription est validée ! Nous vous remercions de votre confiance et nous sommes ravis de vous compter parmi nos Influencers de l'agence.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (32,"fr","Votre inscription est validée",s,"Votre inscription est validée",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
Your account is validated !\n
We thank you for your trust and we are pleased to count you among our Influencers of our agency !\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>Your account is now validated ! We thank you for your trust and we are pleased to count you among our Influencers of our agency!</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (32,"en","Your account is validated",s,"Your account is validated",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
Merci de l'intérêt que pour porter à notre agence.\n
Nous sommes cependant au regret de décliner votre demande d'inscription suite à certains critères non confirmes à l'agence.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Merci de l'intérêt porté à notre agence. Nous sommes cependant au regret de décliner votre demande d'inscription suite à certains critères non conformes à l'agence.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (33,"fr","Votre inscription n'est pas validée",s,"Votre inscription n'est pas validée",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
We appreciate your interest in Salfatix Media and the time you've invested i applying to be an Influencer.\n
Unfortunately, you have not been selected to be an Influencer with our Agency.\n
\n
We encourage you to apply again when you believe your profile matches what we are looking for.\n
\n
We wish you good luck with your future endeavors.\n
\n
Best,\n
\n
Salfatix Media\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>We appreciate your interest in Salfatix Media and the time you've invested i applying to be an Influencer.</p>"||
    "<p>Unfortunately, you have not been selected to be an Influencer with our Agency.<br /></p>"||
    "<p>We encourage you to apply again when you believe your profile matches what we are looking for.<br /></p>"||
    "<p>We wish you good luck with your future endeavors.<br /></p>"||
    "<p>Best,<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (33,"en","Your account is rejected",s,"Your account is rejected",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
Féliciations !! Votre profil a été présélectionné pour le deal #CAMPAIGN_NAME# !\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Féliciations !! Votre profil a été présélectionné pour le deal #CAMPAIGN_NAME# !<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (50,"fr","Votre profil est présélectionné pour un deal",s,"Votre profil est présélectionné pour un deal",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
Congratulations! You have been selected for #CAMPAIGN_NAME# deal! Please proceed with the next steps.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>Congratulations! You have been selected for #CAMPAIGN_NAME# deal! Please proceed with the next steps.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (50,"en","You are selected for a deal",s,"You are selected for a deal",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
après étude de la sélection par la marque, votre profil n'a pas été retenu pour cette collaboration #CAMPAIGN_NAME#.\n
Nous vous invitons à suivre et postuler aux autres deals en cours.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>après étude de la sélection par la marque, votre profil n'a pas été retenu pour cette collaboration #CAMPAIGN_NAME#.</p>"||
    "<p>Nous vous invitons à suivre et postuler aux autres deals en cours.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (51,"fr","Votre profil n'a pas été retenu pour un deal",s,"Votre profil n'a pas été retenu pour un deal",s1);

LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.\n
\n
Unfortunately, you have not been approved to proceed with this deal.\n
\n
Best,\n
\n
Salfatix Media\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.</p>"||
    "<p>Unfortunately, you have not been approved to proceed with this deal.<br /></p>"||
    "<p>Best,<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (51,"en","You are not selected for a deal",s,"You are not selected for a deal",s1);

LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
le deal #CAMPAIGN_NAME# vient d'être lancé. Laissez libre court à votre créativité !\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>le deal #CAMPAIGN_NAME# vient d'être lancé. Laissez libre court à votre créativité !<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (52,"fr","Un deal vient de démarrer",s,"Un deal vient de démarrer",s1);

LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
#CAMPAIGN_NAME# deal bas been launched. Give free rein to your creativity!\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>#CAMPAIGN_NAME# deal bas been launched. Give free rein to your creativity!<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (52,"en","A deal is launched",s,"A deal is launched",s1);

LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
nous n'avons pas encore recu l'ensemble du travail attendu pour le deal #CAMPAIGN_NAME#.\n
N'hésitez pas à nous contacter si vous rencontrez un problème pour la livraison des posts.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>nous n'avons pas encore recu l'ensemble du travail attendu pour le deal #CAMPAIGN_NAME#.</p>"||
    "<p>N'hésitez pas à nous contacter si vous rencontrez un problème quant à la livraison des posts.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (53,"fr","Post attendu pour un deal",s,"Post attendu pour un deal",s1);

LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
we have not received all of the expected work for the #CAMPAIGN_NAME# deal yet.\n
Do not hesitate to contact us if you have a problem with the delivery of posts.\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>we have not received all of the expected work for the #CAMPAIGN_NAME# deal yet.</p>"||
    "<p>Do not hesitate to contact us if you have a problem with the delivery of posts.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (53,"en","Post awaited for a deal",s,"Post awaited for a deal",s1);

LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
après étude par la marque, certains posts du deal #CAMPAIGN_NAME# ne correspondent pas aux attentes de la marque.\n
Une nouvelle version est attendu pour ces posts.\n
Vous pouvez voir la liste complète des posts en vous connectant à votre application SalfatixMedia.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Après étude par la marque, certains posts du deal #CAMPAIGN_NAME# ne correspondent pas aux attentes de la marque.</p>"||
    "<p>Une nouvelle version est attendu pour ces posts.</p>"||
    "<p>Vous pouvez voir la liste complète des posts en vous connectant à votre application SalfatixMedia.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (54,"fr","Post non retenu pour un deal",s,"Post non retenu pour un deal",s1);

LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
after study by the brand, some posts of the #CAMPAIGN_NAME# deal do not meet the expectations of the brand.\n
A new version is expected for these posts.\n
You can see the full list of posts by logging into your SalfatixMedia app.\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>after study by the brand, some posts of the #CAMPAIGN_NAME# deal do not meet the expectations of the brand.</p>"||
    "<p>A new version is expected for these posts.</p>"||
    "<p>You can see the full list of posts by logging into your SalfatixMedia app.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (54,"en","Post rejected for a deal",s,"Post rejected for a deal",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
votre travail concernant le deal #CAMPAIGN_NAME# a été validé.\n
Il ne vous reste plus qu'à rendre publique l'ensemble de votre travail sur les réseaux sociaux.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>votre travail concernant le deal #CAMPAIGN_NAME# a été validé.</p>"||
    "<p>Il ne vous reste plus qu'à rendre publique l'ensemble de votre travail sur les réseaux sociaux.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (55,"fr","Post validé pour un deal",s,"Post validé pour un deal",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
your work on deal #CAMPAIGN_NAME# has been validated.\n
All you have to do is publicize all of your work on social networks.\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>your work on deal #CAMPAIGN_NAME# has been validated.</p>"||
    "<p>All you have to do is to make public all of your work on social networks.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (55,"en","Post validated for a deal",s,"Post validated for a deal",s1);
----
LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
Pouvez vous nous envoyer les statistiques de vos posts pour le deal #CAMPAIGN_NAME# ?\n
Merci.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Pouvez vous nous envoyer les statistiques de vos posts pour le deal #CAMPAIGN_NAME# ?</p>"||
    "<p>Merci.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (56,"fr","Statistiques attendues pour un deal",s,"Statistiques attendues pour un deal",s1);

LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
Can you send us the statistics of your posts for the #CAMPAIGN_NAME# deal?\n
Thank you.\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>Can you send us the statistics of your posts for the #CAMPAIGN_NAME# deal?</p>"||
    "<p>Thank you.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (56,"en","Statistics awaited for a deal",s,"Statistics awaited for a deal",s1);
----
LET s = "Bonjour !\n
\n
Votre campagne #CAMPAIGN_NAME# a été retenue et nous sommes d'ors et déjà au travail.\n
Nous reviendrons vers vous sous peu pour discuter de la suite des opérations.
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>Votre campagne #CAMPAIGN_NAME# a été retenue et nous sommes d'ors et déjà au travail.</p>"||
    "<p>Nous reviendrons vers vous sous peu pour discuter de la suite des opérations.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (57,"fr","Campagne acceptée",s,"Campagne acceptée",s1);
LET s = "Hello !\n
\n
Your campaign #CAMPAIGN_NAME# has caught our attention. We are already working on it\n
We will shortly come back to you to discuss next steps to take.\n
\n
Team @salfatixMedia\n"
LET s1 = "Hello !"||
    "<p>Your campaign #CAMPAIGN_NAME# has caught our attention. We are already working on it.</p>"||
    "<p>We will shortly come back to you to discuss next steps to take.</p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (57,"en","Campaign approved",s,"Campaign approved",s1);

LET s = "Bonjour #INFLUENCER_FIRSTNAME#!\n
\n
Nous apprécions votre intérêt pour la campagne #CAMPAIGN_NAME# et le temps investi à la séléctionner.\n
Malheureusement, votre proposition de prix n'a pas été acceptée. Nous vous avons envoyé une nouvelle proposition.\n
N'hésitez pas vérifier et valider cette nouvelle proposition si elle vous convient.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour #INFLUENCER_FIRSTNAME#!"||
    "<p>Nous apprécions votre intérêt pour la campagne #CAMPAIGN_NAME# et le temps investi à la séléctionner.</p>"||
    "<p>Malheureusement, votre proposition de prix n'a pas été acceptée. Nous vous avons envoyé une nouvelle proposition.<br />N'hésitez pas vérifier et valider cette nouvelle proposition si elle vous convient.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (58,"fr","Nouvelle offre pour un deal",s,"Nouvelle offre pour un deal",s1);
LET s = "Hello #INFLUENCER_FIRSTNAME#!\n
\n
We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.\n
\n
Unfortunately, the price you've proposed has not been accepted. We've resent you this deal with a new proposal.\n
Do not hesitate to check and apply to the deal #CAMPAIGN_NAME# if that new proposal suites you.\n
\n
Best,\n
\n
Salfatix Media\n"
LET s1 = "Hello #INFLUENCER_FIRSTNAME#!"||
    "<p>We appreciate your interest in the #CAMPAIGN_NAME# deal and the time you've invested in applygin to take part in the deal with the Brand.</p>"||
    "<p>Unfortunately, the price you've proposed has not been accepted. We've resent you this deal with a new proposal.<br />Do not hesitate to check and apply to the deal #CAMPAIGN_NAME# if that new proposal suites you.<br /></p>"||
    "<p>Best,<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (58,"en","New proposal for a deal",s,"New proposal for a deal",s1);
----
LET s = "Bonjour !\n
\n
pour réinitialiser votre mot de passe cliquez sur le lien ci-dessous:\n
\n
#LINK_RESET_PASSWORD#\n
\n
Si vous n'avez pas fait cette demande, merci d'ignorer cet email.\n
\n
La Team @SalfatixMedia\n"
LET s1 = "Bonjour !"||
    "<p>pour réinitialiser votre mot de passe cliquez <a href=\"#LINK_RESET_PASSWORD#\">ici</a>.</p>"||
    "<br />"||
    "<p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br />"||
    "<p><a href=\"#LINK_RESET_PASSWORD#\">#LINK_RESET_PASSWORD#</a><br /></p>"||
    "<br />"||
    "<p>Si vous n'avez pas fait cette demande, merci d'ignorer cet email.<br /></p>"||
    "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">La Team Salfatix Media<br /></p>"||
    "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (1000,"fr","Réinitialisez votre mot de passe",s,"Réinitialisez votre mot de passe",s1);

LET s = "Hello !\n
\n
to reset your password click the link below:\n
\n
#LINK_RESET_PASSWORD#\n
\n
If you did not request a new password, please ignore this email.\n
\n
Team @SalfatixMedia\n"
LET s1 = "Hello !"||
         "<p>To reset your password click <a href=\"#LINK_RESET_PASSWORD#\">here</a>.</p>"||
         "<br />"||
         "<p>If, for whatever reason, this link doesn't start a thing, please copy paste following URL in your favorite browser :<br />"||
         "<a href=\"#LINK_RESET_PASSWORD#\">#LINK_RESET_PASSWORD#</a><br /></p>"||
         "<p>If you did not request a new password, please ignore this email.<br /></p>"||
         "<p><img src=\"#LINK_SIGNATURE_LOGO#\" alt=\"\" width=\"51\" height=\"49\" align=\"middle\">The Team Salfatix Media<br /></p>"||
         "<p><a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a><a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>"
INSERT INTO messages VALUES (1000,"en","Reset password instructions",s,"Reset password instructions",s1);
--End Mails

  Call insertCountries()
  Call insertStates()
  Call insertCities1()
  Call insertCities2()
  Call insertCities3()
  Call insertCities4()
  Call insertCities5()
  Call insertCities6()
  Call insertCities7()
  Call insertCities8()
  Call insertCities9()
  Call insertCities10()
  Call insertCities11()
  Call insertCities12()

  CALL load_pics() 

  INSERT INTO backofficeusers(bousr_id, bousr_password, bousr_pic_id, bousr_gender_id, bousr_firstname, bousr_lastname, bousr_email, bousr_country_id, bousr_isadmin, bousr_accountstatus_id, bousr_creationdate) 
  VALUES (1, '$2a$10$C7rV3y/kCahvYjUoQchw5OVTI9YQL.eEoQwzEhYPcPRGIJuV3i6Xq', 1, 1, 'Jeanne', 'Denfer', 'admin@4js.com', 75, 1, 1, CURRENT);

Insert into brands values (1,1,"Brand-A","www.4js.com",75,953,74133,"55","Rue du Faubourg Saint Honoré","75000","","",1,2,"Jean","Tenrien","Head of development","testa@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);
Insert into brands values (2,1,"Brand-B","www.fourjs.com",75,953,74133,"40B","Avenue de Suffren","75015","","",1,3,"Jeanne","Denfer","CEO","testb@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);

Insert into brandcategories values (1,32,1);
Insert into brandcategories values (2,28,1);
Insert into brandcategories values (2,34,0);

Insert into brandsocialnetworks values (1,1,3,"Brand-A",NULL);

Insert into brandsocialnetworks values (0,1,9,"https://www.4js.com",Null);

Try
  Call insertInfluencersUTF8()
Catch
  Display "Problème d'encoding dans DB à prévoir..."
  Call insertInfluencersANSI()
End Try

End Function

Function insertInfluencersUTF8()
Insert into users values (0,3,"Rebecca","Westberg","07/22/1980","testc@4js.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",2,3407,318518,"","Emirates Airline Service delivery","25155","","",97200000000000,9322788,"miss.rebeccaisabelle","Rebecca Isabelle","","#Swedish #globalista 👱🏽‍♀️Based in #Dubai 🇦🇪","",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
Insert into users values (0,3,"irina","peicu","06/12/1985","testd@4js.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO3",12,205,NULL,"","","","","",4312341234,13327500,"irinahp","Irina","",
"","https://www.instagram.com/irinahp/",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
End Function

Function insertInfluencersANSI()
Insert into users values (0,3,"Rebecca","Westberg","07/22/1980","testc@4js.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",2,3407,318518,"","Emirates Airline Service delivery","25155","","",97200000000000,9322788,"miss.rebeccaisabelle","","","","",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
Insert into users values (0,3,"irina","peicu","06/12/1985","testd@4js.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO3",12,205,NULL,"","","","","",4312341234,13327500,"irinahp","","","","https://www.instagram.com/irinahp/",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
End Function
