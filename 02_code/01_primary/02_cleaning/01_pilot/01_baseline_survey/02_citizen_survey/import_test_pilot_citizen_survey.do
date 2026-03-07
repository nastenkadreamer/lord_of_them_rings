* import_test_pilot_citizen_survey.do
*
* 	Imports and aggregates "test_pilot_citizen_survey" (ID: test_pilot_citizen_survey) data.
*
*	Inputs:  "test_pilot_citizen_survey_WIDE.csv"
*	Outputs: "test_pilot_citizen_survey.dta"
*
*	Output by SurveyCTO February 10, 2026 6:08 AM.

* initialize Stata
clear all
set more off
set mem 100m


* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "test_pilot_citizen_survey_WIDE.csv"
local dtafile "test_pilot_citizen_survey.dta"
local corrfile "test_pilot_citizen_survey_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid devicephonenum username device_info duration stamp_1 survey_date_scto surveyor_name surv_id surveyor_other supervisor_name supervisor_other id_main hhid survey_status_other"
local text_fields2 "refusal_reason_other audio_audit q1_6_name q1_12_hh_relation_other q1_13_education_other q1_18_hh_income_sources q1_17_hh_income_sources_other q1_19_hh_primary_income_other q1_23_land_unit_other"
local text_fields3 "hh_govjob_now hh_govjob_past q1_15_jati q1_17_jati_other q1_17_religion_other q4_7_reason_leaders_not_help q4_7_reason_leaders_not_help_oth q5_4_topics_recent_gs q5_4_topics_recent_gs_oth"
local text_fields4 "q5_5_spoke_in_recent_sabha_other q5_6_input_given q5_8_reasons_not_attend q5_8_reasons_not_attend_other q5_9_biggest_challenge_other q5_10_second_biggest_challenge_o q6_1_investment_openended"
local text_fields5 "q7_4_types_2yrs q7_4_types_2yrs_oth q8_4_who_retrieves q8_4_who_retrieves_other q8_1_primary_drinking_source_oth q8_38_months_hh q8_9_reasons_hh q8_9_reasons_cannot_get_all_wate"
local text_fields6 "q8_14_water_acceptable_other q8_4_who_retrieves_ls q8_4_who_retrieves_ls_other q8_1_primary_source_ls q8_38_months_ls q8_9_reasons_ls q8_9_reasons_cannot_get_all_wate q8_31_crops_kharif"
local text_fields7 "q8_31_crops_kharif_oth q8_33_crops_rabi q8_33_crops_rabi_ot q8_28_irrigation_primary_source_ q8_29_how_get_water_to_fields_ot q8_40_months_ag q8_42_events_last_5yrs q8_42_events_last_5yrs_other"
local text_fields8 "gp_water_assets q10_2_af break_rule1 break_rule2 ph_no ph_no_check match_ph_no surv_comp surveyor_comments instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable surveyor "<>Surveyor: What is your name?"
	note surveyor: "<>Surveyor: What is your name?"
	label define surveyor 1 "Akhilesh Mandoi" 2 "Dharmendra Barman" 3 "Dinesh Lodhi" 4 "Jyoti Pashi" 5 "Mamta Garg" 6 "Mukesh Kanash" 7 "Reena Bhagel" 8 "Anju Patel" -97 "Others"
	label values surveyor surveyor

	label variable surveyor_other "If other, please write your name"
	note surveyor_other: "If other, please write your name"

	label variable supervisor "<>Surveyor: What is your supervisor's name?"
	note supervisor: "<>Surveyor: What is your supervisor's name?"
	label define supervisor 1 "Govind Singh" 2 "Anindya Singh" -97 "Other"
	label values supervisor supervisor

	label variable supervisor_other "If other, please write your name"
	note supervisor_other: "If other, please write your name"

	label variable block_id "Block:"
	note block_id: "Block:"
	label define block_id 3554 "Barwani" 3559 "Pansemal" 3555 "Pati" 3558 "Rajpur"
	label values block_id block_id

	label variable gp_id "In which GP do you live?"
	note gp_id: "In which GP do you live?"
	label define gp_id 132830 "Ambapani" 132844 "Bijasan" 132831 "Amlyapani" 132832 "Awalda" 132841 "Bhavti" 132833 "Badgaon" 132834 "Bagud" 132835 "Bajatta Khurd" 132845 "Bomya" 132836 "Balkunwa" 132837 "Barukhodra" 132838 "Barwani Khurd" 250914 "Barwani" 132839 "Bengalgaon" 132840 "Bhandarda" 132842 "Bhilkheda" 132843 "Bhurakunwa" 132861 "Mardai" 132847 "Borlay" 132846 "Bori" 132848 "Charankheda" 132849 "Chiklya" 132873 "Sajwani Kham" 132850 "Dhamnai" 132851 "Dhanora" 132857 "Kasrawad" 132852 "Gothanya" 132853 "Hirkray" 132854 "Holgaon" 132866 "Pichhodi" 132855 "Kajalmata" 132856 "Kalyanpura" 132868 "Piplaj" 132858 "Keli" 132859 "Lonsara Khurd" 132860 "Malurana" 132862 "Menimata" 132863 "Morkatta" 132876 "Sukhpuri" 132864 "Panchpula Dakshin" 132865 "Panchpula Uttar" 132867 "Pipari" 132871 "Rehgun" 132869 "Rasgaon" 132880 "Umedada" 132870 "Rehgun" 132872 "Sajwani" 132874 "Silawad" 132875 "Soundul" 132877 "Sustikheda" 132878 "Talun Khurd" 132879 "Talwada Bujurg" 132881 "Vedpuri" 132946 "Malgaon" 132926 "Alkhad" 132931 "Baygor" 132924 "Aamada" 132925 "Aamjhiri" 132952 "Nisarpur" 132927 "Baljhiri" 132928 "Bandhara Bujurg" 132929 "Bandhara Khurd" 132930 "Bandriyabad" 132960 "Shivnipadawa" 132932 "Behadiya" 132938 "Ghattya" 132933 "Bhadgon" 132934 "Bhatki" 132936 "Dhawdi" 132950 "Moyda" 132953 "Oswada" 132955 "Piprani" 132962 "Vangara" 132935 "Devdhar" 132937 "Dondwada" 132939 "Gongwada" 132942 "Junapani" 132940 "Jahur" 132941 "Jalgon" 132943 "Kansul" 132944 "Karanpura" 132954 "Pannali" 132961 "Temla" 132956 "Raikhed" 132945 "Malfa" 132947 "Mankui" 132948 "Matrala" 132949 "Mortalai" 132951 "Nandiyabad" 132957 "Rakhi Bujurg" 132958 "Rakhi Khurd" 132959 "Sakrali Bujurg" 132975 "Devgarh" 132964 "Anjrada" 132965 "Atarsumbha" 132963 "Aawali" 132996 "Rosar" 132966 "Bamnali" 132967 "Bedada" 132999 "Semlet" 132986 "Kumbhkhet" 132997 "Rosmal" 132968 "Bokrata" 132969 "Borkhedi" 132971 "Chervi" 132970 "Budi" 132991 "Pati" 132988 "Osada" 132995 "Ranipura" 132972 "Chikalkunwawadi" 132985 "Khajpur" 132973 "Chouki" 132998 "Sawriyapani" 132974 "Derwaliya" 132976 "Dhamariya" 132977 "Dongargaon" 132989 "Pakhalya" 132978 "Gandhawal" 132979 "Gara" 132981 "Gudi" 132994 "Pospur" 132980 "Golpatiwadi" 132982 "Harla" 132993 "Pokhalya" 132984 "Kandra" 132992 "Piparkund" 132983 "Junajhira" 133003 "Than" 132987 "Limbi" 133006 "Valan" 133000 "Semli" 132990 "Palwat" 133001 "Shivani" 133002 "Sindhi" 133004 "Thengcha" 133005 "Ubadgarh" 133008 "Agalgaon" 133028 "Jalgone" 133014 "Bhorwada" 133009 "Baghad" 133010 "Bakwadi" 133011 "Balsamund" 133012 "Bhagsur" 133013 "Bhami" 133042 "Mojali Khurd" 133064 "Sangvi Neem" 133015 "Bilwani" 133016 "Bobalwadi" 133058 "Rewja" 133017 "Budra" 133020 "Chotariya" 133018 "Chhoti Khargone" 133019 "Chitawal" 133069 "Siwai" 133021 "Danod" 133023 "Dewla" 133022 "Devnali" 133024 "Ekalwara" 133025 "Ghusgaon" 133062 "Salkheda" 133031 "Julwaniya" 133026 "Indrapur" 133027 "Jahur" 133029 "Jalkheda" 133030 "Jodai" 133032 "Kadwi" 133033 "Kansel" 133037 "Kusmari" 133034 "Khadki" 133067 "Sidadi" 133035 "Khajuri" 133038 "Lafangaon" 133036 "Kukdiya Kheda" 133039 "Limbai" 133040 "Mandil" 133051 "Nihali" 133041 "Matli" 133071 "Temala" 133043 "Morani" 133044 "Morgun" 133045 "Moyda" 133057 "Relwa Bujurg" 133048 "Nanded" 133046 "Nagalwadi Bujurg" 133047 "Nagalwadi Khurd" 133049 "Nandgaon" 133050 "Naravla" 133052 "Ozar" 133054 "Panwa" 133055 "Pipari Bujurg" 133072 "Than" 133056 "Rangaon Road" 133059 "Rui" 133060 "Sali" 133061 "Salikala" 133063 "Sangaon" 133065 "Sangvi Than" 133066 "Sawarda" 133068 "Singun" 133070 "Takli" 133073 "Upala" 133074 "Vaswi"
	label values gp_id gp_id

	label variable village_id "In which village do you live?"
	note village_id: "In which village do you live?"
	label define village_id 478471 "Akal Amba" 478436 "Alkhad" 478496 "Alkhad Bada" 478478 "Alkhard Chhota" 478466 "Amba Padaw" 478421 "Amda" 478407 "Amjhiri" 478463 "Amliya Pani" 478405 "Babultad" 478425 "Baljhiri" 478427 "Bandhara Buzurg" 478444 "Bandhara Khurd" 478474 "Bandiyasemal" 478398 "Bandryabad" 478490 "Banjardipardwa" 478397 "Baygore" 478404 "Behdiya" 478479 "Bhadbhada" 478410 "Bhadgone" 478465 "Bhagal Amba" 478400 "Bhatki" 478491 "Bheshmal" 478460 "Charli Pitha" 478455 "Chichlya" 478442 "Chikhlada" 478435 "Choonabhatti" 478492 "Choutiyapani" 478432 "Deodhar" 478424 "Dharadgaon" 478394 "Dhawadi" 478431 "Diwadya" 478468 "Dolarjhar Amba" 478449 "Donwada" 478438 "Gendhari" 478439 "Ghathya" 478413 "Gongwada" 478426 "Gorikheda" 478489 "Guraedpani" 478450 "Harnya" 478412 "Jahur" 478429 "Jaitpura" 478430 "Jalgone" 478472 "Jalyapani" 478494 "Jhendiya Kunda" 478420 "Junapani" 478487 "Kalaamba" 478461 "Kamttihee Nala" 478481 "Kanjapani" 478422 "Kansul" 478399 "Karanpura" 478470 "Kel Amba" 478453 "Khadikham" 478423 "Khadki" 478475 "Khamghat" 478406 "Khetiya (Revenue Area)" 478408 "Khodamohali" 478482 "Kunjarwarda" 478459 "Lalvaniya" 478485 "Mahujhira" 478402 "Malfa" 478401 "Malgaon" 478451 "Malkatar" 478467 "Manjani" 478440 "Mankui" 478484 "Mapati" 478448 "Matrala" 478415 "Melan" 478414 "Mendrana" 478464 "Mogara Pani" 478488 "Mohalayapani" 478409 "Mortalay" 478452 "Moyda" 478458 "Nandyabad" 478434 "Nanwanya" 478473 "Neel Bawardi" 478457 "Nihalamba" 478411 "Nisarpur" 478447 "Oswada" 478456 "Padlya" 478469 "Palaniya" 478418 "Pannali" 951378 "Pansemal" 478419 "Piparani" 478495 "Pipliya Pani" 478445 "Piplod" 478437 "Raichul" 478441 "Raikheda" 478417 "Rajpura" 478396 "Rakhi Buzurg" 478395 "Rakhi Khurd" 478428 "Rampura" 478477 "Saap Khadki" 478443 "Sakrali Buzurg" 478446 "Sakrali Khurd" 478433 "Sanpkhadki" 478493 "Shivanipadauta" 478416 "Temala" 478403 "Temli" 478462 "Tilli Khet" 478480 "Umarbeda" 478483 "Valpani" 478486 "Vasalyapani" 478454 "Wangra" 478080 "Ajanyapani" 478081 "Amba Pani" 477985 "Amlali" 478078 "Amliya Pani" 478008 "Amlyapani" 477988 "Awalda" 477989 "Babultad" 478009 "Badgaon" 478016 "Bagud" 478027 "Bajatta Buzurg" 478028 "Bajatta Khurd" 477997 "Balkhad" 478032 "Balkunwa" 478054 "Barukhodra" 478005 "Barwani Khurd" 478006 "Barwani Revenue Area" 478075 "Bawangaja" 478038 "Begalgaon" 477991 "Bhamta" 478064 "Bhandarda" 477986 "Bhawati" 478000 "Bhilkheda" 478073 "Bhurakuwa" 477984 "Bijasan" 478004 "Bomya" 478071 "Borchapada" 478024 "Borelaya" 478041 "Bori" 478055 "Charankheda" 478052 "Cheeklya Malan" 478068 "Chiklya" 478015 "Dehdala" 478037 "Dhaba Bawardi" 478035 "Dhamnai" 478062 "Dhamodi" 478022 "Dhanora" 478011 "Ekalara" 478012 "Gajnera" 478069 "Golbavadi" 478061 "Gothanya" 478050 "Hirkaray" 478057 "Holgaon" 478065 "Jadakau" 478003 "Jamda" 477987 "Jangharwa" 478077 "Kachali Khodari" 477996 "Kajalmata" 478074 "Kajalmata" 478076 "Kalakhet" 478002 "Kalyanpura" 478072 "Kanjakuwa" 478079 "Kanjapani" 478014 "Kari" 951376 "Kasba Barwani" 478013 "Kasrawad" 477993 "Kathora" 478042 "Keli" 478017 "Khedi" 478001 "Kukra" 478030 "Lonsara Buzurg" 478029 "Lonsara Khurd" 478053 "Malurana" 478070 "Mardai" 478044 "Menimata" 477983 "Morktta" 477992 "Nainpura" 478047 "Naktimata" 477998 "Nandgaon" 478051 "Panchpala Dakshin" 478063 "Panchpala Uttara" 477999 "Pendra" 477994 "Pichhodi" 478023 "Pipari Buzurg" 478020 "Piplaj" 478019 "Piplod" 478059 "Raichuli" 478043 "Rasgaon" 478048 "Ratdiyamal" 478060 "Rehgun" 478036 "Rehgun (Sajwani)" 478034 "Sajwani" 478033 "Sajwani Kham" 478040 "Samarkheda" 478010 "Sangaon" 478007 "Segaon Revenue Area" 478018 "Segawan" 478056 "Silawad" 477995 "Sirsani" 477990 "Sondul" 478046 "Sukhpuri" 478045 "Sustikheda" 478025 "Taloon Buzurg" 478026 "Taloon Khurd" 478031 "Talwada Buzurg" 478058 "Tangda" 478067 "Temla" 478049 "Umedada" 478021 "Utawad" 478039 "Varlyapani" 478066 "Vedpuri" 478176 "Ambi" 478191 "Amliya Pani" 478096 "Anjarada" 478129 "Atarsanbha" 478101 "Awali" 478187 "Bada" 478162 "Baidi Falya" 478088 "Bamnali" 478119 "Berada" 478141 "Bhadal" 478113 "Bhaisari" 478180 "Bhanij Kundiya" 478110 "Bokarata" 478082 "Borkhedi" 478163 "Borkund" 478097 "Budi" 478103 "Chakalya" 478095 "Chandan Devi" 478116 "Charpatiya" 478151 "Chervi" 478175 "Chhichwaniya" 478121 "Chikalkuwa Badi" 478092 "Chipiya Khedi" 478108 "Chouki" 478169 "Dabari" 478114 "Derwalya" 478174 "Devgarh" 478132 "Dhamariya" 478143 "Dhanjara" 478127 "Dogargaon" 478133 "Donglyapani" 478136 "Dongriya Khodra" 478161 "Edari" 478190 "Fundriya Pani" 478115 "Gandhaval" 478120 "Gariya" 478159 "Gatabara" 945485 "Ghatbara (F)" 478155 "Ghonghsa" 478091 "Ghunghasi" 478154 "Golgaon" 478177 "Golpatibaidi" 478084 "Gudi" 478189 "Gulriya Pani" 478183 "Hanuman Mali" 478168 "Harla" 478184 "Hatbavadi" 478170 "Jaie" 478118 "Jhamar" 478173 "Jharar" 478146 "Jiwani" 478140 "Junazira" 478130 "Kadawalya" 478111 "Kalakhet" 478139 "Kalakhet" 478182 "Kalmiya Jhawar" 478148 "Kari" 478093 "Khajpur" 478145 "Kherwani" 478123 "Kiradi" 478086 "Koondra Served" 478085 "Koondra Unsevered" 478142 "Kotbandhani" 478156 "Kuli" 478112 "Kumbhkhet" 478160 "Laijhapi" 478150 "Lekhrda" 478087 "Limbi" 478185 "Magarpati" 478107 "Matarkund" 478153 "Medhkimal" 478099 "Megha" 478178 "Morani" 478105 "Muvaswada" 478157 "Nalti" 478158 "Newa" 478094 "Osada" 478138 "Pakhalya" 478106 "Palwat" 478122 "Panchgaon" 478100 "Pati" 478171 "Piparkund" 478124 "Pokhaliya" 478090 "Pospur" 478179 "Ramgarh" 478117 "Ranipura" 478186 "Rankui Pitha (Ajrad)" 478083 "Rosar" 478181 "Roshmal" 478149 "Sagbara" 478172 "Sagmal" 478126 "Sapai Duwali" 478102 "Sawariyapani" 478147 "Semlar" 478089 "Semli" 478137 "Semliya Khodra" 478192 "Semlya Khodara" 478166 "Shivni" 478125 "Sindhi" 478135 "Sindhi Khodri" 478164 "Sindhwani" 478152 "Siraspani" 478109 "Tapar" 478128 "Tapkala" 478134 "Than" 478131 "Thengcha" 478144 "Tuwarkherda" 478167 "Ubadgarh" 478188 "Umariya Pani" 478104 "Valan" 478165 "Van" 478098 "Verwada" 478362 "Agalgaon" 478337 "Atarsanbha" 478380 "Awalya" 478389 "Baghad" 478361 "Bajad" 478358 "Bakwadi" 478382 "Balsamund" 478298 "Bhagsur" 478297 "Bhami" 478318 "Bhilkheda" 478379 "Bhorwada" 478372 "Bhulgaon" 478308 "Bilwani" 478374 "Bobalwadi" 478316 "Borali" 478302 "Budra" 478310 "Chautariya" 478360 "Chhotikhargaon" 478368 "Chitawal" 478349 "Damdami" 478309 "Danodroud" 478329 "Deola" 478390 "Deonali" 478323 "Ekalbara" 478328 "Gawha" 478375 "Ghusgaon" 478381 "Golpura" 478342 "Gondpura" 478336 "Haldad" 478311 "Indarpur(Rehatiya)" 478367 "Jahoor" 478338 "Jalgaon" 478315 "Jalkheda" 478325 "Jodai" 478335 "Julwaniya Road" 478370 "Kadwi" 478300 "Kasel" 478354 "Khadkal" 478305 "Khadki" 478312 "Khadkya Mhow" 478363 "Khajuri" 478392 "Khapar Kheda" 478321 "Kukadiya Kheda" 478339 "Kusmari" 478304 "Lachchhi" 478383 "Lahadgaon" 478391 "Laphangaon" 478307 "Limbai" 478357 "Lingwa" 478346 "Mandil" 478327 "Mandwadi" 478324 "Matli" 478385 "Matmur" 478320 "Mojali Buzurg" 478319 "Mojali Khurd" 478303 "Morani" 478352 "Morgun" 478341 "Moyada" 478355 "Mundla" 478386 "Naded" 478393 "Nagalwadi Buzurg" 478377 "Nagalwadi Khurd" 478348 "Nandgaon" 478306 "Narawala" 478326 "Nihali(Jodai)" 478334 "Nihali(Julwaniya)" 478376 "Nilkanth" 478378 "Ozar" 478369 "Padala (Kadwi)" 951377 "Palsud" 478330 "Panwa" 478353 "Pipri Buzurg" 478299 "Raipura" 478344 "Rajpur(Revenue Area)" 478356 "Relva Buzurg" 478364 "Relwa Khurd" 478332 "Rengaon Road" 478317 "Revja" 478333 "Rojhani" 478371 "Rui" 478296 "Sali(Bhagsur)" 478387 "Salikalan" 478388 "Salitanda" 478340 "Salkheda" 478350 "Sangaon" 478373 "Sangwi(Bhulgaon)" 478365 "Sangwi (Than)" 478322 "Sawarda" 478313 "Sidadi" 478301 "Singun" 478347 "Siwai" 478384 "Takli" 478351 "Temala Khurd" 478343 "Temla Buzurg" 478331 "Temla(Panwa)" 478366 "Than" 478345 "Unchi" 478314 "Upla" 478359 "Waswi"
	label values village_id village_id

	label variable id "If Attempt 1 : Please assign a number to this household. eg, if this is the thir"
	note id: "If Attempt 1 : Please assign a number to this household. eg, if this is the third household you are visiting in this village, write down 3. Please refer to your tracking sheet while entering this number"

	label variable survey_status "Survey Status: What is the status of the survey?"
	note survey_status: "Survey Status: What is the status of the survey?"
	label define survey_status 1 "Available to be surveyed" 2 "Appointment" 3 "Not available during revisit period (NAW)" 4 "Not available during surveyors' work hours (NAT)" 5 "Refused the survey (RR)" 6 "House locked" -997 "Other"
	label values survey_status survey_status

	label variable survey_status_other "Specify"
	note survey_status_other: "Specify"

	label variable refusal_reason "What is the reason for refusal of the survey?"
	note refusal_reason: "What is the reason for refusal of the survey?"
	label define refusal_reason 1 "Survey length is too long" 2 "Trust issues/ suspects fraud" 3 "Unavailable during survey hours" 4 "Physically/mentally challenged" 5 "No benefit from the survey" -997 "Other (specify)" -998 "Can’t say" -999 "Refused to respond"
	label values refusal_reason refusal_reason

	label variable refusal_reason_other "Specify"
	note refusal_reason_other: "Specify"

	label variable consent "Do you wish to participate in this survey?"
	note consent: "Do you wish to participate in this survey?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable q_audio_consent "Do you consent to this survey being recorded?"
	note q_audio_consent: "Do you consent to this survey being recorded?"
	label define q_audio_consent 1 "Yes" 0 "No"
	label values q_audio_consent q_audio_consent

	label variable q1_6_name "Please write the name of the person you are speaking with."
	note q1_6_name: "Please write the name of the person you are speaking with."

	label variable q1_10_age "What is your age? (in years)"
	note q1_10_age: "What is your age? (in years)"

	label variable q1_11_gender "Please choose the respondent's gender."
	note q1_11_gender: "Please choose the respondent's gender."
	label define q1_11_gender 1 "Female" 0 "Male" -997 "Other" -998 "Don't know" -999 "Refused to respond"
	label values q1_11_gender q1_11_gender

	label variable q1_12_hh_relation "What is the your relationship with the household head?"
	note q1_12_hh_relation: "What is the your relationship with the household head?"
	label define q1_12_hh_relation 1 "Household head" 2 "Spouse of HH head" 3 "Child of HH head" 4 "Sibling of HH head" 5 "Parent of HH head" 6 "Daughter-in-law/son-in-law of head" 7 "Grandchildren of HH head" 8 "Spouse of sibling of HH head" 9 "Grandparent of HH head" 10 "Niece/nephew of HH head" 11 "Uncle/aunt of the HH head" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_12_hh_relation q1_12_hh_relation

	label variable q1_12_hh_relation_other "Please specify"
	note q1_12_hh_relation_other: "Please specify"

	label variable q1_12_marital_status "What is your marital status?"
	note q1_12_marital_status: "What is your marital status?"
	label define q1_12_marital_status 0 "Never married" 1 "Currently married" 2 "Separated or divorced" 3 "Widowed" -998 "Don't know" -999 "Refused to respond"
	label values q1_12_marital_status q1_12_marital_status

	label variable q1_13_education "What is the highest level of education that you have completed?"
	note q1_13_education: "What is the highest level of education that you have completed?"
	label define q1_13_education 1 "No schooling" 2 "Primary" 3 "Secondary" 4 "Higher Secondary" 5 "Diploma" 6 "Started college did not finish" 7 "College graduate" 8 "Postgraduate" 9 "Advance degree after postgraduate" 10 "Religious study" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_13_education q1_13_education

	label variable q1_13_education_other "If other, please specify"
	note q1_13_education_other: "If other, please specify"

	label variable q1_24_hh_size "Including yourself, how many members usually live in your household and share a "
	note q1_24_hh_size: "Including yourself, how many members usually live in your household and share a kitchen with you?"

	label variable q1_25_num_under6 "How many people in your household are under the age of 6 years?"
	note q1_25_num_under6: "How many people in your household are under the age of 6 years?"

	label variable q1_26_num_6_18 "How many people in your household are between 6 and 18 years old?"
	note q1_26_num_6_18: "How many people in your household are between 6 and 18 years old?"

	label variable q1_27_num_over55 "How many people in your household are older than age 55?"
	note q1_27_num_over55: "How many people in your household are older than age 55?"

	label variable q1_18_hh_income_sources "I am going to read out loud ways some ways that people earn money. Tell me, for "
	note q1_18_hh_income_sources: "I am going to read out loud ways some ways that people earn money. Tell me, for each of these, whether someone in your household did any of these in the past year."

	label variable q1_17_hh_income_sources_other "If other, please specify"
	note q1_17_hh_income_sources_other: "If other, please specify"

	label variable q1_19_hh_primary_income "Out of all these ways that your household earns money, what would you say is you"
	note q1_19_hh_primary_income: "Out of all these ways that your household earns money, what would you say is your household's primary source of income?"
	label define q1_19_hh_primary_income 1 "Agricultural work on your HH’s land, either leased or owned and products are bei" 2 "Animal husbandry and products are being sold" 3 "Self-employment/small business of your own or your HH’s (e.g., sewing, making ba" 4 "Any income generating under SRLM/SHG" 5 "Casual agricultural labour on someone else’s land" 6 "Casual non-agricultural labour (Hint: construction work and other ad hoc daily w" 7 "NREGA work" 8 "Salaried regular/wage employment (Employed in an enterprise, Teaching, Anganwadi" 9 "Pension (widow, old age, disability)" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_19_hh_primary_income q1_19_hh_primary_income

	label variable q1_19_hh_primary_income_other "If other, please specify"
	note q1_19_hh_primary_income_other: "If other, please specify"

	label variable hh_ag_yes_else "Does anyone in your household grow produce or crops, whether to sell or for your"
	note hh_ag_yes_else: "Does anyone in your household grow produce or crops, whether to sell or for your own consumption?"
	label define hh_ag_yes_else 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values hh_ag_yes_else hh_ag_yes_else

	label variable q1_20a_bicycle "Does anyone in your household own: Bicycle?"
	note q1_20a_bicycle: "Does anyone in your household own: Bicycle?"
	label define q1_20a_bicycle 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20a_bicycle q1_20a_bicycle

	label variable q1_20b_motorcycle "Does anyone in your household own: Motorcycle/Scooter?"
	note q1_20b_motorcycle: "Does anyone in your household own: Motorcycle/Scooter?"
	label define q1_20b_motorcycle 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20b_motorcycle q1_20b_motorcycle

	label variable q1_20c_smartphone "Does anyone in your household own: Phone?"
	note q1_20c_smartphone: "Does anyone in your household own: Phone?"
	label define q1_20c_smartphone 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20c_smartphone q1_20c_smartphone

	label variable q1_20d_tv "Does anyone in your household own: Television?"
	note q1_20d_tv: "Does anyone in your household own: Television?"
	label define q1_20d_tv 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20d_tv q1_20d_tv

	label variable q1_20h_cattle "Does anyone in your household own: Cattle: Cows/Buffaloes/Ox?"
	note q1_20h_cattle: "Does anyone in your household own: Cattle: Cows/Buffaloes/Ox?"
	label define q1_20h_cattle 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20h_cattle q1_20h_cattle

	label variable q1_20h_cattle_2 "How many do you own?"
	note q1_20h_cattle_2: "How many do you own?"

	label variable q1_20i_goats "Does anyone in your household own: Goats/Sheep?"
	note q1_20i_goats: "Does anyone in your household own: Goats/Sheep?"
	label define q1_20i_goats 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20i_goats q1_20i_goats

	label variable q1_20i_goats_2 "How many do you own?"
	note q1_20i_goats_2: "How many do you own?"

	label variable q1_20j_othlivestock "Does your household have any other livestock?"
	note q1_20j_othlivestock: "Does your household have any other livestock?"
	label define q1_20j_othlivestock 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_20j_othlivestock q1_20j_othlivestock

	label variable q1_21_anyone_owns_land "Does any member of your household own any land on which produce or crops can be "
	note q1_21_anyone_owns_land: "Does any member of your household own any land on which produce or crops can be grown?"
	label define q1_21_anyone_owns_land 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_21_anyone_owns_land q1_21_anyone_owns_land

	label variable q1_22_land_size "What is the size of this land holding?"
	note q1_22_land_size: "What is the size of this land holding?"

	label variable q1_23_land_unit "What is the unit of measurement for the landholding?"
	note q1_23_land_unit: "What is the unit of measurement for the landholding?"
	label define q1_23_land_unit 1 "Decimal" 2 "Kathha" 3 "Bhiga" 4 "Acre" 5 "Hectare" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_23_land_unit q1_23_land_unit

	label variable q1_23_land_unit_other "If other, please specify"
	note q1_23_land_unit_other: "If other, please specify"

	label variable q1_28_else_member_not_counted "Is there anyone else you would consider a household member that is not counted i"
	note q1_28_else_member_not_counted: "Is there anyone else you would consider a household member that is not counted in the number of people who usually live with you?"
	label define q1_28_else_member_not_counted 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q1_28_else_member_not_counted q1_28_else_member_not_counted

	label variable q1_29_num_away "How many individuals are temporarily or permanently away from your household?"
	note q1_29_num_away: "How many individuals are temporarily or permanently away from your household?"

	label variable q1_30_mig_remit "How many of these individuals left here to find a job somewhere else?"
	note q1_30_mig_remit: "How many of these individuals left here to find a job somewhere else?"

	label variable q1_31_mig_remit "How many of these individuals regularly send money back to your household to sup"
	note q1_31_mig_remit: "How many of these individuals regularly send money back to your household to support household expenses?"

	label variable hh_govjob "Has anyone in your household ever had a position with the government, such as be"
	note hh_govjob: "Has anyone in your household ever had a position with the government, such as being elected sarpanch, or being appointed, like as an ASHA worker, CRP, or other government position?"
	label define hh_govjob 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values hh_govjob hh_govjob

	label variable hh_govjob_now "Which position(s) does someone in your household currently hold?"
	note hh_govjob_now: "Which position(s) does someone in your household currently hold?"

	label variable hh_govjob_past "Which position(s) did someone in your household previously hold?"
	note hh_govjob_past: "Which position(s) did someone in your household previously hold?"

	label variable hh_shg "Does anyone in your household belong to an SHG? You may have heard this called a"
	note hh_shg: "Does anyone in your household belong to an SHG? You may have heard this called a 'samu'."
	label define hh_shg 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values hh_shg hh_shg

	label variable hh_shg_pres "Is anyone in your household a leader of their SHG? This could mean they are pres"
	note hh_shg_pres: "Is anyone in your household a leader of their SHG? This could mean they are president, secretary, treasurer, etc."
	label define hh_shg_pres 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values hh_shg_pres hh_shg_pres

	label variable q1_15_jati "What is your jati?"
	note q1_15_jati: "What is your jati?"

	label variable q1_17_jati_other "If other, please specify"
	note q1_17_jati_other: "If other, please specify"

	label variable q1_16_social_group "To which of the following groups do you belong?"
	note q1_16_social_group: "To which of the following groups do you belong?"
	label define q1_16_social_group 1 "Scheduled Caste (SC)" 2 "Scheduled Tribe (ST)" 3 "Other Backward Class (OBC)" 4 "General/Other" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_16_social_group q1_16_social_group

	label variable q1_17_religion "What is your religion?"
	note q1_17_religion: "What is your religion?"
	label define q1_17_religion 0 "None" 1 "Hindu" 2 "Muslim" 3 "Christian" 4 "Sikh" 5 "Jain" 6 "Buddhist" 7 "Other, tribal community" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q1_17_religion q1_17_religion

	label variable q1_17_religion_other "If other, please specify"
	note q1_17_religion_other: "If other, please specify"

	label variable hh_info_checkpoint "Is the respondent still there?"
	note hh_info_checkpoint: "Is the respondent still there?"
	label define hh_info_checkpoint 1 "Yes" 0 "No"
	label values hh_info_checkpoint hh_info_checkpoint

	label variable q3_1_borrow_2000_people "If you needed to borrow 6,000 Rupees for an urgent need, how many people outside"
	note q3_1_borrow_2000_people: "If you needed to borrow 6,000 Rupees for an urgent need, how many people outside of your household, but in your village, could you ask for the loan?"

	label variable q3_2_relatives_weekly "How many relatives not living in your household do you speak with at least once "
	note q3_2_relatives_weekly: "How many relatives not living in your household do you speak with at least once a week?"

	label variable q3_3_friends_village_weekly "How many friends in your village (who are not your relatives) do you speak with "
	note q3_3_friends_village_weekly: "How many friends in your village (who are not your relatives) do you speak with at least once a week?"

	label variable q4_2_family_trust "Generally speaking, how much would you say that you can trust members of your fa"
	note q4_2_family_trust: "Generally speaking, how much would you say that you can trust members of your family? Are they completely trustworthy, somewhat trustworthy, not very trustworthy, or not at all trustworthy"
	label define q4_2_family_trust 1 "Completely trustworthy" 2 "Somewhat trustworthy" 3 "Not very trustworthy" 4 "Not at all trustworthy" -998 "Don't know" -999 "Refused to respond"
	label values q4_2_family_trust q4_2_family_trust

	label variable q4_3_friends_trust "What about your friends in your village? How much can they be trusted?"
	note q4_3_friends_trust: "What about your friends in your village? How much can they be trusted?"
	label define q4_3_friends_trust 1 "Completely trustworthy" 2 "Somewhat trustworthy" 3 "Not very trustworthy" 4 "Not at all trustworthy" -998 "Don't know" -999 "Refused to respond"
	label values q4_3_friends_trust q4_3_friends_trust

	label variable q4_4_other_village_people_trust "What about other people in your village? How much can they be trusted?"
	note q4_4_other_village_people_trust: "What about other people in your village? How much can they be trusted?"
	label define q4_4_other_village_people_trust 1 "Completely trustworthy" 2 "Somewhat trustworthy" 3 "Not very trustworthy" 4 "Not at all trustworthy" -998 "Don't know" -999 "Refused to respond"
	label values q4_4_other_village_people_trust q4_4_other_village_people_trust

	label variable q4_5_leaders_trust "What about leaders in your village? How much can they be trusted?"
	note q4_5_leaders_trust: "What about leaders in your village? How much can they be trusted?"
	label define q4_5_leaders_trust 1 "Completely trustworthy" 2 "Somewhat trustworthy" 3 "Not very trustworthy" 4 "Not at all trustworthy" -998 "Don't know" -999 "Refused to respond"
	label values q4_5_leaders_trust q4_5_leaders_trust

	label variable q4_6_leaders_help "In general, do you think your local leaders are able to help you receive benefit"
	note q4_6_leaders_help: "In general, do you think your local leaders are able to help you receive benefits from government programs?"
	label define q4_6_leaders_help 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q4_6_leaders_help q4_6_leaders_help

	label variable leaders_bribe "Do you think local leaders usually want something in exchange to help you? (Hind"
	note leaders_bribe: "Do you think local leaders usually want something in exchange to help you? (Hindi - लेकिन बदले में पैसे/फ़ायदे मांगते हैं)"
	label define leaders_bribe 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values leaders_bribe leaders_bribe

	label variable q4_7_reason_leaders_not_help "What do you think is the reason your local leaders aren’t able to help you? (sel"
	note q4_7_reason_leaders_not_help: "What do you think is the reason your local leaders aren’t able to help you? (select all that apply)"

	label variable q4_7_reason_leaders_not_help_oth "If other, please specify"
	note q4_7_reason_leaders_not_help_oth: "If other, please specify"

	label variable q4_8_conflict_village "In this village, do people generally get along with each other or is there confl"
	note q4_8_conflict_village: "In this village, do people generally get along with each other or is there conflict?"
	label define q4_8_conflict_village 1 "Lot of disagreement" 2 "Some disagreement" 3 "No disagreement" -998 "Don't know" -999 "Refused to respond"
	label values q4_8_conflict_village q4_8_conflict_village

	label variable q4_9_community_collective "If your community were to face some sort of problem like a natural disaster, do "
	note q4_9_community_collective: "If your community were to face some sort of problem like a natural disaster, do you think everyone would come together to solve it, or families would solve it individually?"
	label define q4_9_community_collective 1 "Come together to solve the problem" 2 "Each family solves individually" -998 "Don't know" -999 "Refused to respond"
	label values q4_9_community_collective q4_9_community_collective

	label variable q4_10_untouchability "In your village, to what extent do households practice untouchability?"
	note q4_10_untouchability: "In your village, to what extent do households practice untouchability?"
	label define q4_10_untouchability 1 "Many households practice it" 2 "Some households practice it" 3 "A few households practice it" 4 "No households practice it" -998 "Don't know" -999 "Refused to respond"
	label values q4_10_untouchability q4_10_untouchability

	label variable network_checkpoint "Is the respondent still there?"
	note network_checkpoint: "Is the respondent still there?"
	label define network_checkpoint 1 "Yes" 0 "No"
	label values network_checkpoint network_checkpoint

	label variable q5_2_ward_gram_sabha_past_year "Do you know if there has been a community meeting like a Ward Sabha or Gram Sabh"
	note q5_2_ward_gram_sabha_past_year: "Do you know if there has been a community meeting like a Ward Sabha or Gram Sabha in your village in the past one year?"
	label define q5_2_ward_gram_sabha_past_year 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q5_2_ward_gram_sabha_past_year q5_2_ward_gram_sabha_past_year

	label variable q5_1_ever_attended_gram_sabha "Have you ever attended a community meeting like a ward sabha or a Gram Sabha in "
	note q5_1_ever_attended_gram_sabha: "Have you ever attended a community meeting like a ward sabha or a Gram Sabha in your panchayat?"
	label define q5_1_ever_attended_gram_sabha 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q5_1_ever_attended_gram_sabha q5_1_ever_attended_gram_sabha

	label variable q5_3_attended_past_year "Did you attend your panchayat's most recent Gram Sabha?"
	note q5_3_attended_past_year: "Did you attend your panchayat's most recent Gram Sabha?"
	label define q5_3_attended_past_year 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q5_3_attended_past_year q5_3_attended_past_year

	label variable q5_4_topics_recent_gs "What topics were discussed at the most recent Gram Sabha?"
	note q5_4_topics_recent_gs: "What topics were discussed at the most recent Gram Sabha?"

	label variable q5_4_topics_recent_gs_oth "If other, please specify"
	note q5_4_topics_recent_gs_oth: "If other, please specify"

	label variable q5_5_spoke_in_recent_sabha "Did you speak to provide your input at the most recent Gram Sabha?"
	note q5_5_spoke_in_recent_sabha: "Did you speak to provide your input at the most recent Gram Sabha?"
	label define q5_5_spoke_in_recent_sabha 1 "Yes" 0 "No" -997 "Other (specify)"
	label values q5_5_spoke_in_recent_sabha q5_5_spoke_in_recent_sabha

	label variable q5_5_spoke_in_recent_sabha_other "If other, please specify"
	note q5_5_spoke_in_recent_sabha_other: "If other, please specify"

	label variable q5_6_input_given "What input did you give at the Gram or Ward Sabha?"
	note q5_6_input_given: "What input did you give at the Gram or Ward Sabha?"

	label variable q5_8_reasons_not_attend "Why did you not attend the most recent Gram Sabha? Surveyor: Do not read the opt"
	note q5_8_reasons_not_attend: "Why did you not attend the most recent Gram Sabha? Surveyor: Do not read the options out loud to the respondent. Simply classify the reason(s) they tell you."

	label variable q5_8_reasons_not_attend_other "If other, please specify"
	note q5_8_reasons_not_attend_other: "If other, please specify"

	label variable q5_9_biggest_challenge "What do you think the biggest challenge your community needs to address in the n"
	note q5_9_biggest_challenge: "What do you think the biggest challenge your community needs to address in the next year is?"
	label define q5_9_biggest_challenge 1 "Land issues" 2 "Water issues" 3 "Lack of jobs" 4 "Crime" 5 "Corruption" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q5_9_biggest_challenge q5_9_biggest_challenge

	label variable q5_9_biggest_challenge_other "If other, please specify"
	note q5_9_biggest_challenge_other: "If other, please specify"

	label variable q5_10_second_biggest_challenge "What do you think the second biggest challenge your community needs to address i"
	note q5_10_second_biggest_challenge: "What do you think the second biggest challenge your community needs to address in the next year?"
	label define q5_10_second_biggest_challenge 1 "Land issues" 2 "Water issues" 3 "Lack of jobs" 4 "Crime" 5 "Corruption" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q5_10_second_biggest_challenge q5_10_second_biggest_challenge

	label variable q5_10_second_biggest_challenge_o "If other, please specify"
	note q5_10_second_biggest_challenge_o: "If other, please specify"

	label variable local_leaders "Local leaders"
	note local_leaders: "Local leaders"
	label define local_leaders 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values local_leaders local_leaders

	label variable wealthy_households "Wealthy households"
	note wealthy_households: "Wealthy households"
	label define wealthy_households 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values wealthy_households wealthy_households

	label variable caste_leaders "Caste leaders"
	note caste_leaders: "Caste leaders"
	label define caste_leaders 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values caste_leaders caste_leaders

	label variable womens_groups "Women's groups or Self-Help Groups"
	note womens_groups: "Women's groups or Self-Help Groups"
	label define womens_groups 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values womens_groups womens_groups

	label variable high_caste_members "Community members from high castes"
	note high_caste_members: "Community members from high castes"
	label define high_caste_members 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values high_caste_members high_caste_members

	label variable low_caste_members "Community members from low castes"
	note low_caste_members: "Community members from low castes"
	label define low_caste_members 1 "A lot of influence" 2 "Some influence" 3 "A little influence" 4 "No influence" -998 "Don't know" -999 "Refused to respond"
	label values low_caste_members low_caste_members

	label variable benefits_dist "Are there some hamlets or neighbourhoods in this village that usually receive mo"
	note benefits_dist: "Are there some hamlets or neighbourhoods in this village that usually receive more government benefits than others?"
	label define benefits_dist 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values benefits_dist benefits_dist

	label variable q5_11_more_say "Would you like to have more say in decisions that are made in the community?"
	note q5_11_more_say: "Would you like to have more say in decisions that are made in the community?"
	label define q5_11_more_say 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q5_11_more_say q5_11_more_say

	label variable q6_1_investment_openended "Now imagine your community has approximately 10 lakhs it can spend in the next y"
	note q6_1_investment_openended: "Now imagine your community has approximately 10 lakhs it can spend in the next year on an investment. What would you want the community to spend this money on?"

	label variable comm_gov_checkpoint "Is the respondent still there?"
	note comm_gov_checkpoint: "Is the respondent still there?"
	label define comm_gov_checkpoint 1 "Yes" 0 "No"
	label values comm_gov_checkpoint comm_gov_checkpoint

	label variable q7_mgnregs_aware "Did you already know about the MGNREGS program before I explained it to you?"
	note q7_mgnregs_aware: "Did you already know about the MGNREGS program before I explained it to you?"
	label define q7_mgnregs_aware 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q7_mgnregs_aware q7_mgnregs_aware

	label variable q7_1_mgnregs_jobcard "Do you or anyone in your household have a MGNREGS job card? The job card mention"
	note q7_1_mgnregs_jobcard: "Do you or anyone in your household have a MGNREGS job card? The job card mentions details of all eligible members of the household that can work for MGNREGS. If any member of the household works, that information is registered in the job card."
	label define q7_1_mgnregs_jobcard 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q7_1_mgnregs_jobcard q7_1_mgnregs_jobcard

	label variable q7_2_demand "Has anyone in your household ever demanded work under MGNREGS? By this I mean wh"
	note q7_2_demand: "Has anyone in your household ever demanded work under MGNREGS? By this I mean whether you've ever asked a local leader for work under MGNREGS."
	label define q7_2_demand 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q7_2_demand q7_2_demand

	label variable q7_3_worked "Has anyone in your household ever worked for MGNREGS?"
	note q7_3_worked: "Has anyone in your household ever worked for MGNREGS?"
	label define q7_3_worked 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q7_3_worked q7_3_worked

	label variable q7_2_worked "When was the last time anyone in your household worked for MGNREGS?"
	note q7_2_worked: "When was the last time anyone in your household worked for MGNREGS?"

	label variable q7_3_projects "Do you know what types of projects have been implemented in your village under t"
	note q7_3_projects: "Do you know what types of projects have been implemented in your village under the MGNREGS scheme?"
	label define q7_3_projects 1 "Yes" 0 "No"
	label values q7_3_projects q7_3_projects

	label variable q7_4_types_2yrs "What types of projects have been implemented in your village under the MGNREGS s"
	note q7_4_types_2yrs: "What types of projects have been implemented in your village under the MGNREGS scheme? Note for the surveyor: Do not read options out loud. Simply mark the options the respondent says."

	label variable q7_4_types_2yrs_oth "If other, please specify"
	note q7_4_types_2yrs_oth: "If other, please specify"

	label variable mnrega_exp_checkpoint "Is the respondent still there?"
	note mnrega_exp_checkpoint: "Is the respondent still there?"
	label define mnrega_exp_checkpoint 1 "Yes" 0 "No"
	label values mnrega_exp_checkpoint mnrega_exp_checkpoint

	label variable q8_wells_own "Does your household own any private borewells or tubewells?"
	note q8_wells_own: "Does your household own any private borewells or tubewells?"
	label define q8_wells_own 1 "Yes" 0 "No" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_wells_own q8_wells_own

	label variable q8_wells_count "How many borewells or tubewells do you own in total?"
	note q8_wells_count: "How many borewells or tubewells do you own in total?"

	label variable q8_drink_public "First, think about the primary source of drinking water for your household. Does"
	note q8_drink_public: "First, think about the primary source of drinking water for your household. Does that water come directly to your house or compound?"
	label define q8_drink_public 1 "Yes" 0 "No" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_drink_public q8_drink_public

	label variable q8_2_time_roundtrip_minutes "How long does it take to go there, get water, and come back? (minutes)"
	note q8_2_time_roundtrip_minutes: "How long does it take to go there, get water, and come back? (minutes)"

	label variable q8_drink_livestock "Is this water source also the primary way you water household livestock?"
	note q8_drink_livestock: "Is this water source also the primary way you water household livestock?"
	label define q8_drink_livestock 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q8_drink_livestock q8_drink_livestock

	label variable q8_5_trips_last_week "How many trips did anyone from your household make to collect water from that so"
	note q8_5_trips_last_week: "How many trips did anyone from your household make to collect water from that source, whether for drinking water or any other reason, in the last week?"

	label variable q8_4_who_retrieves "Who from your household normally retrieves water for any type of use from that w"
	note q8_4_who_retrieves: "Who from your household normally retrieves water for any type of use from that water source? (up to 3)"

	label variable q8_4_who_retrieves_other "If other, please specify"
	note q8_4_who_retrieves_other: "If other, please specify"

	label variable q8_6_other_households_share_sour "In addition to your household, how many other households access their drinking w"
	note q8_6_other_households_share_sour: "In addition to your household, how many other households access their drinking water from the main source from which you access water?"

	label variable q8_1_primary_drinking_source "Do you know where this water originally comes from?"
	note q8_1_primary_drinking_source: "Do you know where this water originally comes from?"
	label define q8_1_primary_drinking_source 1 "Borehold or tubewell" 2 "Water from a well" 3 "Surface water (river, stream, dam, lake, pond, canal, irrigation channel)" 4 "Rainwater collection" 5 "Tanker-truck" 6 "Water tank" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_1_primary_drinking_source q8_1_primary_drinking_source

	label variable q8_1_primary_drinking_source_oth "If other, please specify"
	note q8_1_primary_drinking_source_oth: "If other, please specify"

	label variable q8_8_sufficient_last_yr "In the last year, has there been any time when your household did not have suffi"
	note q8_8_sufficient_last_yr: "In the last year, has there been any time when your household did not have sufficient quantities of drinking water when needed?"
	label define q8_8_sufficient_last_yr 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q8_8_sufficient_last_yr q8_8_sufficient_last_yr

	label variable q8_8_lack_timing "Were these times intermittent (off and on throughout the year) or more seasonal "
	note q8_8_lack_timing: "Were these times intermittent (off and on throughout the year) or more seasonal (happened in specific months)?"
	label define q8_8_lack_timing 1 "Intermittant/off-and-on" 2 "Seasonal"
	label values q8_8_lack_timing q8_8_lack_timing

	label variable q8_38_months_hh "In what months were you not able to access enough water for household needs?"
	note q8_38_months_hh: "In what months were you not able to access enough water for household needs?"

	label variable q8_9_reasons_hh "Why can’t you get all the water your household needs? Note to surveyor: Read the"
	note q8_9_reasons_hh: "Why can’t you get all the water your household needs? Note to surveyor: Read the response options out loud to the respondent (excluding don't know and refuse)."

	label variable q8_9_reasons_cannot_get_all_wate "If other, please specify"
	note q8_9_reasons_cannot_get_all_wate: "If other, please specify"

	label variable q8_11_monthly_payment_inr "How much do you pay to access water from this source in an ordinary month? (INR)"
	note q8_11_monthly_payment_inr: "How much do you pay to access water from this source in an ordinary month? (INR)"

	label variable q8_14_water_acceptable "Is the water supplied from your main source usually acceptable? If unacceptable,"
	note q8_14_water_acceptable: "Is the water supplied from your main source usually acceptable? If unacceptable, select the main reason."
	label define q8_14_water_acceptable 1 "Yes, acceptable" 2 "No, unacceptable taste" 3 "No, unacceptable colour" 4 "No, unacceptable smell" 5 "No, contains materials" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values q8_14_water_acceptable q8_14_water_acceptable

	label variable q8_14_water_acceptable_other "If other, please specify"
	note q8_14_water_acceptable_other: "If other, please specify"

	label variable q8_15_animals_get_water "Does your household use a different primary source of water for livestock?"
	note q8_15_animals_get_water: "Does your household use a different primary source of water for livestock?"
	label define q8_15_animals_get_water 1 "Yes" 0 "No"
	label values q8_15_animals_get_water q8_15_animals_get_water

	label variable q8_drink_ls "Does that water for your livestock come directly to your house or compound?"
	note q8_drink_ls: "Does that water for your livestock come directly to your house or compound?"
	label define q8_drink_ls 1 "Yes" 0 "No" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_drink_ls q8_drink_ls

	label variable q8_2_time_trip_ls "How long does it take to go there, get water, and come back? (minutes)"
	note q8_2_time_trip_ls: "How long does it take to go there, get water, and come back? (minutes)"

	label variable q8_5_trips_last_week_ls "How many trips did anyone from your household make to collect water from that so"
	note q8_5_trips_last_week_ls: "How many trips did anyone from your household make to collect water from that source, whether for drinking water or any other reason, in the last week?"

	label variable q8_4_who_retrieves_ls "Who from your household normally retrieves water for any type of use from that w"
	note q8_4_who_retrieves_ls: "Who from your household normally retrieves water for any type of use from that water source? (up to 3)"

	label variable q8_4_who_retrieves_ls_other "If other, please specify"
	note q8_4_who_retrieves_ls_other: "If other, please specify"

	label variable q8_6_hhs_share_ls "In addition to your household, how many other households access water from this "
	note q8_6_hhs_share_ls: "In addition to your household, how many other households access water from this source?"

	label variable q8_1_source_ls "Do you know where this water originally comes from?"
	note q8_1_source_ls: "Do you know where this water originally comes from?"
	label define q8_1_source_ls 1 "Borehold or tubewell" 2 "Water from a well" 3 "Surface water (river, stream, dam, lake, pond, canal, irrigation channel)" 4 "Rainwater collection" 5 "Tanker-truck" 6 "Water tank" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_1_source_ls q8_1_source_ls

	label variable q8_1_primary_source_ls "If other, please specify"
	note q8_1_primary_source_ls: "If other, please specify"

	label variable q8_8_sufficient_last_yr_ls "In the last year, has there been any time when your household did not get suffic"
	note q8_8_sufficient_last_yr_ls: "In the last year, has there been any time when your household did not get sufficient water for your livestock from this source?"
	label define q8_8_sufficient_last_yr_ls 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q8_8_sufficient_last_yr_ls q8_8_sufficient_last_yr_ls

	label variable q8_8_lack_timing_ls "Were these times intermittent (off and on throughout the year) or more seasonal "
	note q8_8_lack_timing_ls: "Were these times intermittent (off and on throughout the year) or more seasonal (happened in specific months)?"
	label define q8_8_lack_timing_ls 1 "Intermittant/off-and-on" 2 "Seasonal"
	label values q8_8_lack_timing_ls q8_8_lack_timing_ls

	label variable q8_38_months_ls "In what months were you not able to access enough water for household needs?"
	note q8_38_months_ls: "In what months were you not able to access enough water for household needs?"

	label variable q8_9_reasons_ls "Why can’t you get all the water your household needs from this source? Note to s"
	note q8_9_reasons_ls: "Why can’t you get all the water your household needs from this source? Note to surveyor: Read the response options out loud to the respondent (excluding don't know and refuse)."

	label variable q8_9_reasons_cannot_get_all_wate "If other, please specify"
	note q8_9_reasons_cannot_get_all_wate: "If other, please specify"

	label variable q8_11_monthly_payment_ls_inr "How much do you pay to access water from this source in an ordinary month? (INR)"
	note q8_11_monthly_payment_ls_inr: "How much do you pay to access water from this source in an ordinary month? (INR)"

	label variable water_avail_checkpoint "Is the respondent still there?"
	note water_avail_checkpoint: "Is the respondent still there?"
	label define water_avail_checkpoint 1 "Yes" 0 "No"
	label values water_avail_checkpoint water_avail_checkpoint

	label variable q8_31_crops_kharif "What crops has your household cultivated this kharif season? (Select multiple)"
	note q8_31_crops_kharif: "What crops has your household cultivated this kharif season? (Select multiple)"

	label variable q8_31_crops_kharif_oth "If other, please specify"
	note q8_31_crops_kharif_oth: "If other, please specify"

	label variable q8_33_crops_rabi "What crops did your household cultivate in the previous rabi season?"
	note q8_33_crops_rabi: "What crops did your household cultivate in the previous rabi season?"

	label variable q8_33_crops_rabi_ot "If other, please specify"
	note q8_33_crops_rabi_ot: "If other, please specify"

	label variable q8_26_irrigation_past_year "In the past year, did your household irrigate any fields or gardens?"
	note q8_26_irrigation_past_year: "In the past year, did your household irrigate any fields or gardens?"
	label define q8_26_irrigation_past_year 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q8_26_irrigation_past_year q8_26_irrigation_past_year

	label variable q8_28_irr_source "What is the primary source of water for your household’s irrigation activities?"
	note q8_28_irr_source: "What is the primary source of water for your household’s irrigation activities?"
	label define q8_28_irr_source 1 "Borehold or tubewell" 2 "Water from a well" 3 "Surface water (river, stream, dam, lake, pond, canal, irrigation channel)" 4 "Rainwater collection" 5 "Tanker-truck" 6 "Water tank" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_28_irr_source q8_28_irr_source

	label variable q8_28_irrigation_primary_source_ "If other, please specify"
	note q8_28_irrigation_primary_source_: "If other, please specify"

	label variable q8_29_pump "How do you normally get water from the source onto your fields for irrigation?"
	note q8_29_pump: "How do you normally get water from the source onto your fields for irrigation?"
	label define q8_29_pump 1 "Diesel motor pump" 2 "Electric pump" 3 "Solar pump" 4 "Naturally (gravity)" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_29_pump q8_29_pump

	label variable q8_29_how_get_water_to_fields_ot "If other, please specify"
	note q8_29_how_get_water_to_fields_ot: "If other, please specify"

	label variable q8_32_cost_irr_kharif "How much did it cost you to irrigate these crops in the latest kharif season? Pl"
	note q8_32_cost_irr_kharif: "How much did it cost you to irrigate these crops in the latest kharif season? Please consider any payments for water and payments for electricity for pumps, etc."

	label variable q8_34_cost_irr_rabi "How much did it cost you to irrigate these crops in the latest rabi season?"
	note q8_34_cost_irr_rabi: "How much did it cost you to irrigate these crops in the latest rabi season?"

	label variable q8_37_lack_irr "At any time in the past year, was there not enough water from the source to meet"
	note q8_37_lack_irr: "At any time in the past year, was there not enough water from the source to meet your need?"
	label define q8_37_lack_irr 1 "Yes" 0 "No"
	label values q8_37_lack_irr q8_37_lack_irr

	label variable q8_40_months_ag "If yes, in what months were you not able to access enough water for agricultural"
	note q8_40_months_ag: "If yes, in what months were you not able to access enough water for agricultural needs?"

	label variable q8_30_share_irr "In addition to your household, how many other households access their water from"
	note q8_30_share_irr: "In addition to your household, how many other households access their water from the main source from which you access water for irrigation?"

	label variable hh_ag_yes_checkpoint "Is the respondent still there?"
	note hh_ag_yes_checkpoint: "Is the respondent still there?"
	label define hh_ag_yes_checkpoint 1 "Yes" 0 "No"
	label values hh_ag_yes_checkpoint hh_ag_yes_checkpoint

	label variable q8_41_change_last_5yrs "In your opinion, how has the availability of water changed for your household ov"
	note q8_41_change_last_5yrs: "In your opinion, how has the availability of water changed for your household over the last 5 years?"
	label define q8_41_change_last_5yrs 1 "Improved significantly" 2 "Improved slightly" 3 "Stayed the same" 4 "Worsened slightly" 5 "Worsened significantly" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values q8_41_change_last_5yrs q8_41_change_last_5yrs

	label variable q8_42_events_last_5yrs "Have any of the following things occurred to your household over the past 5 year"
	note q8_42_events_last_5yrs: "Have any of the following things occurred to your household over the past 5 years? (Select all that apply)"

	label variable q8_42_events_last_5yrs_other "If other, please specify"
	note q8_42_events_last_5yrs_other: "If other, please specify"

	label variable know_water_level "Do you know how deep local residents must dig to get to water that can be pumped"
	note know_water_level: "Do you know how deep local residents must dig to get to water that can be pumped to the surface? Often this is the depth of local wells."
	label define know_water_level 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values know_water_level know_water_level

	label variable q8_36_depth_feet "Approximately how many feet underground does water reside in this area?"
	note q8_36_depth_feet: "Approximately how many feet underground does water reside in this area?"

	label variable gp_water_assets "Has your GP done any of the following in the past 5 years?"
	note gp_water_assets: "Has your GP done any of the following in the past 5 years?"

	label variable gp_water_equi "Do you think some people in your village have an easier time accessing water tha"
	note gp_water_equi: "Do you think some people in your village have an easier time accessing water than others do?"
	label define gp_water_equi 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values gp_water_equi gp_water_equi

	label variable wat_know_wellirr "Drilling more borewells or tubewells to irrigate crops"
	note wat_know_wellirr: "Drilling more borewells or tubewells to irrigate crops"
	label define wat_know_wellirr 1 "Increase local water availability" 2 "Decrease local water availability" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_wellirr wat_know_wellirr

	label variable wat_know_welldr "Drilling more borewells or tubewells for drinking water or water for livestock"
	note wat_know_welldr: "Drilling more borewells or tubewells for drinking water or water for livestock"
	label define wat_know_welldr 1 "Increase local water availability" 2 "Decrease local water availability" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_welldr wat_know_welldr

	label variable wat_know_tank "Constructing or installing tanks to store rainwater"
	note wat_know_tank: "Constructing or installing tanks to store rainwater"
	label define wat_know_tank 1 "Increase local water availability" 2 "Decrease local water availability" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_tank wat_know_tank

	label variable wat_know_pond "Constructing or maintaining farm ponds"
	note wat_know_pond: "Constructing or maintaining farm ponds"
	label define wat_know_pond 1 "Increase local water availability" 2 "Decrease local water availability" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_pond wat_know_pond

	label variable wat_know_plant "Planting trees"
	note wat_know_plant: "Planting trees"
	label define wat_know_plant 1 "Increase local water availability" 2 "Decrease local water availability" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_plant wat_know_plant

	label variable wat_know_well2 "If many households start drilling deeper borewells, what happens to your well’s "
	note wat_know_well2: "If many households start drilling deeper borewells, what happens to your well’s water level? Will it increase, decrease or stay the same"
	label define wat_know_well2 1 "Increase water in my well" 2 "Decrease water in my well" 3 "Not affect it" 4 "It depends" -997 "Other (specify)" -998 "Don't know" -999 "Refused to respond"
	label values wat_know_well2 wat_know_well2

	label variable water_avail_loc_checkpoint "Is the respondent still there?"
	note water_avail_loc_checkpoint: "Is the respondent still there?"
	label define water_avail_loc_checkpoint 1 "Yes" 0 "No"
	label values water_avail_loc_checkpoint water_avail_loc_checkpoint

	label variable affor_mod_decide "Has anyone from your household ever worked for afforestation of your own or vill"
	note affor_mod_decide: "Has anyone from your household ever worked for afforestation of your own or villages forests?"
	label define affor_mod_decide 1 "Yes" 0 "No"
	label values affor_mod_decide affor_mod_decide

	label variable q10_1_af "In the last 12 months, did you or anyone in your household work in an MGNREGS pr"
	note q10_1_af: "In the last 12 months, did you or anyone in your household work in an MGNREGS project that involved Plantation or Afforestation?"
	label define q10_1_af 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q10_1_af q10_1_af

	label variable q10_2_af "In which of these locations were the trees planted? (selet all that apply)"
	note q10_2_af: "In which of these locations were the trees planted? (selet all that apply)"

	label variable q10_3_af "How many trees/saplings were planted under community/government schemes on your "
	note q10_3_af: "How many trees/saplings were planted under community/government schemes on your household's private land in the last 5 years?"

	label variable q10_4_af "In the last 12 months, has your household contributed financially or with labor "
	note q10_4_af: "In the last 12 months, has your household contributed financially or with labor to the maintenance or protection of trees planted under any government/community scheme?"
	label define q10_4_af 1 "Yes, financially" 2 "Yes, through labor" 3 "Yes, both" 4 "No" -999 "Don’t know"
	label values q10_4_af q10_4_af

	label variable q10_5_af "Does your household own or use any equipment specifically bought for maintenance"
	note q10_5_af: "Does your household own or use any equipment specifically bought for maintenance of community trees or forest assets?"
	label define q10_5_af 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q10_5_af q10_5_af

	label variable q10_6_af "What is the primary source from which your household accesses firewood/fodder?"
	note q10_6_af: "What is the primary source from which your household accesses firewood/fodder?"
	label define q10_6_af 1 "Community forest/Afforestation area" 2 "Private land/trees" 3 "Open access area/Unprotected forest" 4 "Market purchase" -997 "Other (specify)"
	label values q10_6_af q10_6_af

	label variable q10_7_af "In the past 12 months, has your household been prevented from accessing firewood"
	note q10_7_af: "In the past 12 months, has your household been prevented from accessing firewood or fodder from community land or forest areas?"
	label define q10_7_af 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values q10_7_af q10_7_af

	label variable q10_8_af "Who in your community determines how households can access or harvest resources "
	note q10_8_af: "Who in your community determines how households can access or harvest resources from community afforestation projects?"
	label define q10_8_af 1 "Mukhiya" 2 "Mukhiya Representative" 3 "Ward member" 4 "Other caste leader" 5 "SHG leader" 6 "No one" -997 "Other (specify)"
	label values q10_8_af q10_8_af

	label variable affor_mod_checkpoint "Is the respondent still there?"
	note affor_mod_checkpoint: "Is the respondent still there?"
	label define affor_mod_checkpoint 1 "Yes" 0 "No"
	label values affor_mod_checkpoint affor_mod_checkpoint

	label variable gp_rule1 "Suppose the GP leadership agrees that everyone should limit pumping from borewel"
	note gp_rule1: "Suppose the GP leadership agrees that everyone should limit pumping from borewells during the summer months. How many households do you think would actually follow this rule?"
	label define gp_rule1 1 "None" 2 "A few" 3 "About half" 4 "Most" 5 "All" -998 "Refuse" -999 "Don't know"
	label values gp_rule1 gp_rule1

	label variable break_rule1 "Imagine a rule in your village that no one should pump water from any well after"
	note break_rule1: "Imagine a rule in your village that no one should pump water from any well after 2 PM in the dry season. If someone breaks this rule, what do you think should happen?"

	label variable break_rule2 "What do you think would actually happen in your village if someone were to break"
	note break_rule2: "What do you think would actually happen in your village if someone were to break such a rule?"

	label variable beh_pat1 "Do you agree or disagree? I usually have access to better or more accurate infor"
	note beh_pat1: "Do you agree or disagree? I usually have access to better or more accurate information than others."
	label define beh_pat1 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_pat1 beh_pat1

	label variable beh_pat2 "Do you agree or disagree? It is important to make decisions for those with less "
	note beh_pat2: "Do you agree or disagree? It is important to make decisions for those with less information."
	label define beh_pat2 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_pat2 beh_pat2

	label variable beh_pat3 "Do you agree or disagree? People frequently look to me for leadership in various"
	note beh_pat3: "Do you agree or disagree? People frequently look to me for leadership in various contexts."
	label define beh_pat3 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_pat3 beh_pat3

	label variable beh_equi1 "Do you agree or disagree? I believe some people deserve more success based on th"
	note beh_equi1: "Do you agree or disagree? I believe some people deserve more success based on their efforts or contributions."
	label define beh_equi1 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_equi1 beh_equi1

	label variable beh_equi2 "Do you agree or disagree? I prefer outcomes where resources are distributed equa"
	note beh_equi2: "Do you agree or disagree? I prefer outcomes where resources are distributed equally across groups"
	label define beh_equi2 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_equi2 beh_equi2

	label variable beh_norms1 "Do you agree or disagree? When jobs are scarce, men should have more right to a "
	note beh_norms1: "Do you agree or disagree? When jobs are scarce, men should have more right to a job than women"
	label define beh_norms1 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_norms1 beh_norms1

	label variable beh_norms2 "Do you agree or disagree? A man should have the final word about decisions in hi"
	note beh_norms2: "Do you agree or disagree? A man should have the final word about decisions in his home."
	label define beh_norms2 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_norms2 beh_norms2

	label variable beh_norms3 "Do you agree or disagree? It is important to follow the traditions and customs t"
	note beh_norms3: "Do you agree or disagree? It is important to follow the traditions and customs that are passed down by one’s community or family over time."
	label define beh_norms3 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_norms3 beh_norms3

	label variable behaviour1_checkpoint "Is the respondent still there?"
	note behaviour1_checkpoint: "Is the respondent still there?"
	label define behaviour1_checkpoint 1 "Yes" 0 "No"
	label values behaviour1_checkpoint behaviour1_checkpoint

	label variable beh_risk1 "What would you prefer: A draw with one chance to win INR 600 and the same chance"
	note beh_risk1: "What would you prefer: A draw with one chance to win INR 600 and the same chance of receiving nothing, OR the amount of INR 320 as a sure payment?"
	label define beh_risk1 1 "Take the lottery" 2 "Take the sure thing" -998 "Refuse" -999 "Don't know"
	label values beh_risk1 beh_risk1

	label variable beh_risk2 "What would you prefer: A draw with one chance to win INR 600 and the same chance"
	note beh_risk2: "What would you prefer: A draw with one chance to win INR 600 and the same chance of receiving nothing, OR the amount of INR 100 as a sure payment?"
	label define beh_risk2 1 "Take the lottery" 2 "Take the sure thing" -998 "Refuse" -999 "Don't know"
	label values beh_risk2 beh_risk2

	label variable beh_risk3 "What would you prefer: A draw with one chance to win INR 600 and the same chance"
	note beh_risk3: "What would you prefer: A draw with one chance to win INR 600 and the same chance of receiving nothing, OR the amount of INR 480 as a sure payment?"
	label define beh_risk3 1 "Take the lottery" 2 "Take the sure thing" -998 "Refuse" -999 "Don't know"
	label values beh_risk3 beh_risk3

	label variable beh_recip1 "If someone has harmed you or treated you unfairly, do you settle the score when "
	note beh_recip1: "If someone has harmed you or treated you unfairly, do you settle the score when you get a chance to do it?"
	label define beh_recip1 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values beh_recip1 beh_recip1

	label variable beh_alt1 "Are you willing to give to good causes without expecting anything in return?"
	note beh_alt1: "Are you willing to give to good causes without expecting anything in return?"
	label define beh_alt1 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values beh_alt1 beh_alt1

	label variable beh_recip2 "When someone does you a favor, are you generally willing to return the favor, or"
	note beh_recip2: "When someone does you a favor, are you generally willing to return the favor, or don't worry about it?"
	label define beh_recip2 1 "Yes" 0 "No" -998 "Don't know" -999 "Refused to respond"
	label values beh_recip2 beh_recip2

	label variable beh_risk4 "Would you agree or disagree that you are a person who enjoys taking risks?"
	note beh_risk4: "Would you agree or disagree that you are a person who enjoys taking risks?"
	label define beh_risk4 1 "Agree" 2 "Neither agree nor disagree" 3 "Disagree" -997 "Other (specify)" -998 "Refuse" -999 "Don't know"
	label values beh_risk4 beh_risk4

	label variable beh_timepref1 "Imagine your community can invest in two types of water projects: Which would yo"
	note beh_timepref1: "Imagine your community can invest in two types of water projects: Which would you choose?"
	label define beh_timepref1 1 "Option A: Improves water availability a lot in the next 1–2 years, but benefits " 2 "Option B: Improves water availability only a little now, but benefits continue f"
	label values beh_timepref1 beh_timepref1

	label variable zero_sum1 "In India, there are many different caste groups. If one caste group becomes rich"
	note zero_sum1: "In India, there are many different caste groups. If one caste group becomes richer, this generally comes at the expense of other groups."
	label define zero_sum1 1 "Mostly true" 2 "Mostly false/untrue" -998 "Refuse" -999 "Don't know"
	label values zero_sum1 zero_sum1

	label variable zero_sum2 "In India, there are many different income classes. If one group becomes wealthie"
	note zero_sum2: "In India, there are many different income classes. If one group becomes wealthier, it is usually the case that this comes at the expense of other groups."
	label define zero_sum2 1 "Mostly true" 2 "Mostly false/untrue" -998 "Refuse" -999 "Don't know"
	label values zero_sum2 zero_sum2

	label variable zero_sum3 "When one person in my community gains access to resources from the government, i"
	note zero_sum3: "When one person in my community gains access to resources from the government, it is usually the case that this comes at the expense of someone else."
	label define zero_sum3 1 "Mostly true" 2 "Mostly false/untrue" -998 "Refuse" -999 "Don't know"
	label values zero_sum3 zero_sum3

	label variable zero_sum4 "When one person in my community gains access to an additional source of water, i"
	note zero_sum4: "When one person in my community gains access to an additional source of water, it is usually the case that this comes at the expense of someone else’s access to water."
	label define zero_sum4 1 "Mostly true" 2 "Mostly false/untrue" -998 "Refuse" -999 "Don't know"
	label values zero_sum4 zero_sum4

	label variable behaviour2_checkpoint "Is the respondent still there?"
	note behaviour2_checkpoint: "Is the respondent still there?"
	label define behaviour2_checkpoint 1 "Yes" 0 "No"
	label values behaviour2_checkpoint behaviour2_checkpoint

	label variable phone_yn "Do you have access to a phone anytime?"
	note phone_yn: "Do you have access to a phone anytime?"
	label define phone_yn 1 "Yes" 0 "No"
	label values phone_yn phone_yn

	label variable ph_no "What is your phone number?"
	note ph_no: "What is your phone number?"

	label variable ph_no_check "Please input the phone number again."
	note ph_no_check: "Please input the phone number again."

	label variable gps_houselatitude "A.9) Please record your location (latitude)"
	note gps_houselatitude: "A.9) Please record your location (latitude)"

	label variable gps_houselongitude "A.9) Please record your location (longitude)"
	note gps_houselongitude: "A.9) Please record your location (longitude)"

	label variable gps_housealtitude "A.9) Please record your location (altitude)"
	note gps_housealtitude: "A.9) Please record your location (altitude)"

	label variable gps_houseaccuracy "A.9) Please record your location (accuracy)"
	note gps_houseaccuracy: "A.9) Please record your location (accuracy)"

	label variable consent_check_3 "27) Do you consent to being contacted in the future for follow-up and similar st"
	note consent_check_3: "27) Do you consent to being contacted in the future for follow-up and similar studies?"
	label define consent_check_3 1 "Yes" 0 "No"
	label values consent_check_3 consent_check_3

	label variable consent_check_15 "2.b.) Would you like to keep a print out of the consent which I have just read t"
	note consent_check_15: "2.b.) Would you like to keep a print out of the consent which I have just read to you?"
	label define consent_check_15 1 "Yes" 0 "No"
	label values consent_check_15 consent_check_15

	label variable complete_status "Is the survey complete?"
	note complete_status: "Is the survey complete?"
	label define complete_status 1 "Yes" 0 "No"
	label values complete_status complete_status

	label variable surveyor_comments "Comments for the researcher/ surveyor"
	note surveyor_comments: "Comments for the researcher/ surveyor"






	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  test_pilot_citizen_survey_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}
