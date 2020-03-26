IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL setup
IMPORT FGL brands
IMPORT FGL campaigns

SCHEMA salfatixmedia

PUBLIC CONSTANT
  C_MAINPANEL_JOB_UNVALIDATEDBRAND SMALLINT = 0,
  C_MAINPANEL_JOB_BRANDSWANTTOLEAVE SMALLINT = 1,

  C_MAINPANEL_JOB_UNVALIDATEDINFLUENCER SMALLINT = 10,

  C_MAINPANEL_JOB_UNSUBMITTEDCAMPAIGN SMALLINT = 20,
  C_MAINPANEL_JOB_UNVALIDATEDCAMPAIGN SMALLINT = 21,
  C_MAINPANEL_JOB_UNCOLLECTEDMONEY SMALLINT = 22,
  C_MAINPANEL_JOB_UNPAIDCAMPAIGN SMALLINT = 23,
  C_MAINPANEL_JOB_UNPUBLISHEDCAMPAIGN SMALLINT = 24,
  C_MAINPANEL_JOB_PUBLISHEDCAMPAIGN SMALLINT = 25,
  C_MAINPANEL_JOB_CLOSEDCAMPAIGN SMALLINT = 26,

  C_MAINPANEL_JOB_WAITSALFATIXANSWER SMALLINT = 30,
  C_MAINPANEL_JOB_WAITSALFATIXNEWREMUNERATION SMALLINT = 31,
  C_MAINPANEL_JOB_WAITBRANDANSWER SMALLINT = 32,
  C_MAINPANEL_JOB_INFLREJECTEDBYBRAND SMALLINT = 33,
  C_MAINPANEL_JOB_INFLVALIDATEDBYBRAND SMALLINT = 34,
  C_MAINPANEL_JOB_INFLUNPAID SMALLINT = 35,
  C_MAINPANEL_JOB_INFLGOTPRODUCT SMALLINT = 36,

  C_MAINPANEL_JOB_UNVALIDATEDPOSTPRICES SMALLINT = 50,

  C_MAINPANEL_JOB_LISTALL SMALLINT = 100

PUBLIC TYPE
  t_mainpanel_list RECORD
    job_id INTEGER,
    job_category STRING,
    job_amount INTEGER,
    job_description STRING
  END RECORD

DEFINE --list data
  marec_mainpanel_list DYNAMIC ARRAY OF t_mainpanel_list

#+ Handle backoffice main panel
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION mainpanel_open_form()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_job_id INTEGER,
    i INTEGER,
    ff_formtitle STRING,
    frontcall_return STRING

  OPEN WINDOW w_mainpanel_list WITH FORM "backofficemainpanel_list"
  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Salfatixmedia Back-office"
  CALL FGL_SETTITLE(ff_formtitle)

  CALL mainpanel_initialize_data(marec_mainpanel_list)
    RETURNING lint_ret, lstr_msg
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY marec_mainpanel_list TO scr_mainpanel_list.*
    END DISPLAY
    ON ACTION refresh
      --refresh dashboard
      CALL mainpanel_initialize_data(marec_mainpanel_list)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
    ON ACTION open_job Attributes (Accelerator="return")
      LET i = DIALOG.getCurrentRow("scr_mainpanel_list")
      IF i > 0 THEN
        CASE marec_mainpanel_list[i].job_id
          WHEN C_MAINPANEL_JOB_UNVALIDATEDBRAND
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWBRANDS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_BRANDSWANTTOLEAVE
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWBRANDS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNVALIDATEDINFLUENCER
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWINFLUENCERS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNSUBMITTEDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNVALIDATEDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNCOLLECTEDMONEY
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNPAIDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNPUBLISHEDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_PUBLISHEDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_CLOSEDCAMPAIGN
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_WAITSALFATIXANSWER
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_WAITSALFATIXNEWREMUNERATION
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_WAITBRANDANSWER
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_INFLREJECTEDBYBRAND
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_INFLVALIDATEDBYBRAND
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_INFLUNPAID
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_INFLGOTPRODUCT
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
          WHEN C_MAINPANEL_JOB_UNVALIDATEDPOSTPRICES
            LET lint_ret = 0
            LET lint_action = C_APPACTION_VIEWINFLUENCERS
            LET lint_job_id = marec_mainpanel_list[i].job_id
            EXIT DIALOG
        END CASE
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET lint_job_id = C_MAINPANEL_JOB_LISTALL
      EXIT DIALOG
    BEFORE DIALOG
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"mainpanel_page", setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
  CLOSE WINDOW w_mainpanel_list
  --CALL mainpanel_empty()
    --RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action, lint_job_id
END FUNCTION

#+ Open the empty menu
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION mainpanel_empty()
  DEFINE
    lint_ret INTEGER,
    lint_action INTEGER,
    frontcall_return STRING

  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_salfatix_menu WITH FORM "salfatix_menu"
  MENU ""
    BEFORE MENU
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"mainpanel_page", setup.g_loggedin_name) RETURNING frontcall_return
      CALL DIALOG.setActionHidden("customaction", TRUE)
    ON ACTION customaction
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT MENU
  END MENU
  CLOSE WINDOW w_salfatix_menu
  RETURN lint_ret, lint_action
END FUNCTION

#+ Initializes the main panel data
#+
#+ @param parec_mainpanel_list list of jobs to do
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION mainpanel_initialize_data(parec_mainpanel_list)
  DEFINE
    parec_mainpanel_list DYNAMIC ARRAY OF t_mainpanel_list,
    i INTEGER,
    nb INTEGER,
    larec_list DYNAMIC ARRAY OF INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL parec_mainpanel_list.clear()

  -- BRANDS
  -- To validate
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM brands WHERE @brands.brnd_accountstatus_id = C_ACCOUNTSTATUS_INCOMPLETE
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNVALIDATEDBRAND
      LET parec_mainpanel_list[i].job_category = "Brand"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Unvalidated brand(s)")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- BRANDS
  -- To be removed
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM brands WHERE @brands.brnd_accountstatus_id = C_ACCOUNTSTATUS_WANTTOLEAVE
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_BRANDSWANTTOLEAVE
      LET parec_mainpanel_list[i].job_category = "Brand"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Brand(s) who want(s) to close his/their account")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- INFLUENCERS
  -- To be validated
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM users WHERE @users.usr_accountstatus_id = C_ACCOUNTSTATUS_INCOMPLETE
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNVALIDATEDINFLUENCER
      LET parec_mainpanel_list[i].job_category = "Influencer"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Unvalidated Influencer(s)")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- Under construction
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM campaigns
     WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_CREATED
        OR @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PENDING
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNSUBMITTEDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) under construction")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- To validate
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_SUBMITTED
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNVALIDATEDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) to validate")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- no money collected yet
  TRY
    SELECT COUNT(*)
      INTO nb
    FROM campaigns
    WHERE @campaigns.cmp_campaignstatus_id IN (C_CAMPAIGNSTATUS_VALIDATED, C_CAMPAIGNSTATUS_PUBLISHED, C_CAMPAIGNSTATUS_CLOSED)
      AND @campaigns.cmp_deposit IS NULL
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNCOLLECTEDMONEY
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where no money has been received yet")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- all the campaign's money has not been collected yet
  TRY
    SELECT COUNT(*)
      INTO nb
    FROM campaigns
    WHERE @campaigns.cmp_campaignstatus_id IN (C_CAMPAIGNSTATUS_VALIDATED, C_CAMPAIGNSTATUS_PUBLISHED, C_CAMPAIGNSTATUS_CLOSED)
      AND @campaigns.cmp_deposit IS NOT NULL
      AND @campaigns.cmp_deposit < (
        SELECT NVL(SUM(campaignuserlist.cmpusrl_salfatixtotalprice),0)
        FROM campaignuserlist
        WHERE cmpusrl_campaign_id = @campaigns.cmp_id
      )
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNPAIDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where the brand didn't fully pay you")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- To publish
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_VALIDATED
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNPUBLISHEDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Unpublished campaign(s)")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- Published campaigns
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_PUBLISHEDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Published campaign(s)")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- Closed campaigns
  TRY
    LET nb = 0
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_CLOSED
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_CLOSEDCAMPAIGN
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Closed campaign(s)")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- influencers have applied and agreed with the proposed price
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptbyuser = 1
           AND campaignuserlist.cmpusrl_userwantedprice IS NULL
           AND campaignuserlist.cmpusrl_isacceptedbysalfatix IS NULL)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_WAITSALFATIXANSWER
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where influencers have applied and accepted the proposed remuneration")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY
  -- CAMPAIGNS
  -- influencers have applied and negociate the proposed price
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptbyuser = 1
           AND campaignuserlist.cmpusrl_userwantedprice IS NOT NULL
           AND campaignuserlist.cmpusrl_isacceptedbysalfatix IS NULL)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_WAITSALFATIXNEWREMUNERATION
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where influencers have applied and negociate the remuneration")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY
  -- CAMPAIGNS
  -- SalfatixMedia has accepted influencer and wait brand's answer
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptedbysalfatix = 1
           AND campaignuserlist.cmpusrl_isacceptedbybrand IS NULL)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_WAITBRANDANSWER
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where brand should accept or reject the influencers")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY
  -- CAMPAIGNS
  -- SalfatixMedia has accepted influencer and brand has rejected an influencer
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptedbysalfatix = 1
           AND campaignuserlist.cmpusrl_isacceptedbybrand = 0)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_INFLREJECTEDBYBRAND
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where influencers have been rejected by brand")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY
  -- CAMPAIGNS
  -- SalfatixMedia has accepted influencer and brand has validated an influencer
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptedbybrand = 1)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_INFLVALIDATEDBYBRAND
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where influencers have been validated by brand")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- Need to pay Influencers
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptedbybrand = 1
           AND campaignuserlist.cmpusrl_isuserpaid IS NULL)
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_INFLUNPAID
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) where you have to pay the influencers")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- CAMPAIGNS
  -- Influencers who didn't get the product
  TRY
    SELECT COUNT(*) INTO nb FROM campaigns WHERE @campaigns.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED AND @campaigns.cmp_isproductneeded = 1
      AND EXISTS
        (SELECT campaignuserlist.cmpusrl_campaign_id
           FROM campaignuserlist
         WHERE campaignuserlist.cmpusrl_campaign_id == @campaigns.cmp_id
           AND campaignuserlist.cmpusrl_isacceptedbybrand = 1
           AND (campaignuserlist.cmpusrl_usergotproduct IS NULL OR campaignuserlist.cmpusrl_usergotproduct = 0))
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_INFLGOTPRODUCT
      LET parec_mainpanel_list[i].job_category = "Campaign"
      LET parec_mainpanel_list[i].job_amount = nb
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Campaign(s) for which influencer(s) did not acknowledge the reception of the product")
    END IF

  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  -- POSTS
  -- To validate
  TRY
    SELECT COUNT(DISTINCT userpostprices.usrpp_usr_id) INTO nb FROM userpostprices WHERE @userpostprices.usrpp_isvalidatedbysalfatix = 0
    IF nb > 0 THEN
      LET i = i + 1
      LET parec_mainpanel_list[i].job_id = C_MAINPANEL_JOB_UNVALIDATEDPOSTPRICES
      LET parec_mainpanel_list[i].job_category = "Campaign/Posts"
      LET parec_mainpanel_list[i].job_amount = nb
      --Price(s) per post to validate
      LET parec_mainpanel_list[i].job_description = generateHtmlDescription(parec_mainpanel_list[i].job_amount,parec_mainpanel_list[i].job_category,%"Price(s) per post to validate")
    END IF
  CATCH
    CALL setup.error_log(SQLCA.SQLCODE, SQLERRMESSAGE)
  END TRY

  RETURN 0, NULL
END FUNCTION

Function generateHtmlDescription(nb Integer, Ttl String, Msg String)
  Define
    lMsg   String,
    lStyle String

  Case Ttl
    When "Brand"
      Let lStyle = "color: #fff;"
    When "Influencer"
      Let lStyle = "color: #fff;"
    When "Campaign"
      Let lStyle = "color: #fff;"
    When "Campaign/Posts"
      Let lStyle = "color: #fff;"
  End Case

  Let lMsg = "<div style=\"display: block;grid-template-areas:\n'number       title'\n'number description';\ngrid-template-columns: 20% 80%;width: 256px;grid-gap: 5px;box-sizing: border-box;margin: 2px 2px;padding: 5px 7px;\"><div style=\"grid-area: number;font-size:32px;text-align: left;font-weight: bold;margin: 10px -8px;border-bottom:1px solid;"
  Let lMsg = lMsg.append(lStyle)
  Let lMsg = lMsg.append("\">")
  Let lMsg = lMsg.append(SFMT("%1",nb))
  Let lMsg = lMsg.append("</div><div style=\"grid-area: title;font-size: 24px;font-weight: bold;text-align: left;margin: 10px 0px;")
  Let lMsg = lMsg.append(lStyle)
  Let lMsg = lMsg.append("\">")
  Let lMsg = lMsg.append(LSTR(Ttl.trim()))
	Let lMsg = lMsg.append("</div><div style=\"grid-area: description;font-size:18px;color:#fff;text-align: left;margin: 10px 0px;\">")
  Let lMsg = lMsg.append(Msg.trim())
  Let lMsg = lMsg.append("</div></div>")

  Return lMsg
End Function