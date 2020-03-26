SCHEMA salfatixmedia
TYPE
  t_campaignlist_mobile    RECORD
    campaign                 RECORD LIKE campaigns.*,
    pic_value                LIKE pics.pic_value,
    brnd_name                LIKE brands.brnd_name,
    cmpusrl_usertotalprice   LIKE campaignuserlist.cmpusrl_usertotalprice,
    curcost                  LIKE currencies.crr_name,
    pic_usertotalprice       STRING
                           END RECORD
DEFINE --list data
  marec_campaignlist_mobile DYNAMIC ARRAY OF t_campaignlist_mobile
MAIN
  DEFINE s STRING, t t_campaignlist_mobile
  CLOSE WINDOW SCREEN

  CONNECT TO "salfatixmedia"
  LET s = "SELECT campaigns.*, brands.brnd_name FROM campaigns, brands WHERE cmp_brand_id = brands.brnd_id"
  TRY
    DECLARE c CURSOR FROM s
    FOREACH c
      INTO t.campaign.*,t.brnd_name
      LET t.pic_value = read_pic(t.campaign.cmp_pic_id)
      LET marec_campaignlist_mobile[marec_campaignlist_mobile.getLength()+1].* = t.*
    END FOREACH
    FREE c
  CATCH
    DISPLAY "STATUS = ",STATUS
    EXIT PROGRAM -1
  END TRY

  OPEN WINDOW w WITH FORM "stack"
  DISPLAY ARRAY marec_campaignlist_mobile TO scr_campaign_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY

    ON ACTION reject ATTRIBUTES(ROWBOUND, TEXT="Hide")
    ON ACTION display_campaign
    ON ACTION infl_viewopencampaigns
    ON ACTION infl_viewappliedcampaigns
    ON ACTION infl_viewworkablecampaigns
    ON ACTION cancel ATTRIBUTES(TEXT=%"Back")
      EXIT DISPLAY
  END DISPLAY
  CLOSE WINDOW w
END MAIN

FUNCTION read_pic(i INTEGER)
  DEFINE img BYTE
  LOCATE img IN FILE
  TRY
    SELECT pics.pic_value
      INTO img
    FROM pics
    WHERE pics.pic_id = i
    RETURN img
  CATCH
    RETURN NULL
  END TRY
  RETURN NULL
END FUNCTION
