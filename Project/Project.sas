/* 1: Creating a SAS data set from external files */
PROC IMPORT 
		DATAFILE='/home/u63850716/SAS Project/inability_to_make_ends_meet_percent.csv' 
		OUT=inability_to_make_ends_meet DBMS=CSV REPLACE;
	GETNAMES=YES;
RUN;

/* Import the severe_material_deprivation_percent.csv dataset */
PROC IMPORT 
		DATAFILE='/home/u63850716/SAS Project/severe_material_deprivation_percent.csv' 
		OUT=material_deprivation DBMS=CSV REPLACE;
	GETNAMES=YES;
RUN;

/* 2: Creating and using user-defined formats */
PROC FORMAT;
	VALUE $country_fmt 'Albania'='AL' 'Austria'='AT' 'Belgium'='BE' 
		'Bulgaria'='BG' 'Croatia'='HR' 'Cyprus'='CY' 'Czechia'='CZ' 'Denmark'='DK' 
		'Estonia'='EE' 'Finland'='FI' 'France'='FR' 'Germany'='DE' 'Greece'='GR' 
		'Hungary'='HU' 'Iceland'='IS' 'Ireland'='IE' 'Italy'='IT' 'Kosovo'='XK' 
		'Latvia'='LV' 'Liechtenstein'='LI' 'Lithuania'='LT' 'Luxembourg'='LU' 
		'Malta'='MT' 'Montenegro'='ME' 'Netherlands'='NL' 'North Macedonia'='MK' 
		'Norway'='NO' 'Poland'='PL' 'Portugal'='PT' 'Romania'='RO' 'Serbia'='RS' 
		'Slovakia'='SK' 'Slovenia'='SI' 'Spain'='ES' 'Sweden'='SE' 'Switzerland'='CH' 
		'Turkiye'='TR' OTHER='Other';
RUN;

/* Applying the format */
DATA inability_to_make_ends_meet;
	SET inability_to_make_ends_meet;
	Country_Code=PUT(Country, $country_fmt.);
RUN;

/* 3: Iterative and conditional processing of data */
DATA inability_to_make_ends_meet;
	SET inability_to_make_ends_meet;
	RENAME 'With Great Difficulty'n=With_Great_Difficulty 
		'With Difficulty'n=With_Difficulty 'Some Difficulty'n=Some_Difficulty;
RUN;

DATA inability_severity;
	SET inability_to_make_ends_meet;
	ARRAY difficulties[*] With_Great_Difficulty With_Difficulty Some_Difficulty;
	Severity='Low   ';

	DO i=1 TO DIM(difficulties);

		IF difficulties[i] > 20 THEN
			DO;
				Severity='High';
				LEAVE;
			END;
		ELSE IF difficulties[i] > 10 AND Severity NE 'High' THEN
			Severity='Medium';
	END;
RUN;

PROC PRINT DATA=inability_severity;
RUN;

/* 4: Creating data subsets */
DATA high_severity;
	SET inability_severity;
	WHERE Severity='High';
RUN;

/* 5: Using SAS functions */
DATA inability_with_mean;
	SET inability_to_make_ends_meet;
	Mean_Difficulty=MEAN(OF With_Great_Difficulty With_Difficulty Some_Difficulty);
RUN;

/* 6: Combining data sets with specific SAS and SQL procedures */
PROC SQL;
	CREATE TABLE combined_data AS SELECT a.*, b.Percentage AS Material_Deprivation 
		FROM inability_with_mean AS a LEFT JOIN material_deprivation AS b ON 
		a.Country=b.Country;
QUIT;

/* 7: Normalizing Scores and Categorizing */
DATA inability_normalized;
	SET inability_to_make_ends_meet;
	ARRAY diff[*] With_Great_Difficulty With_Difficulty Some_Difficulty;
	ARRAY norm_diff[3];
	ARRAY norm_cat[3] $12;

	/* Calculate the sum of difficulties for normalization */
	sum_diff=SUM(OF diff[*]);

	/* Normalize the difficulties and categorize them */
	DO i=1 TO DIM(diff);
		norm_diff[i]=diff[i] / sum_diff;

		IF norm_diff[i] > 0.5 THEN
			norm_cat[i]='High';
		ELSE IF norm_diff[i] > 0.2 THEN
			norm_cat[i]='Medium';
		ELSE
			norm_cat[i]='Low';
	END;

	/* Drop the sum_diff variable */
	DROP sum_diff;
RUN;

/* 8: Using report procedures */
PROC PRINT DATA=inability_with_mean;
	TITLE 'Inability to Make Ends Meet with Mean Difficulty';
RUN;

PROC REPORT DATA=high_severity;
	COLUMN Country With_Great_Difficulty With_Difficulty Some_Difficulty Severity;
	DEFINE Country / GROUP;
	DEFINE Severity / DISPLAY;
RUN;

/* 9: Using statistical procedures */
PROC MEANS DATA=inability_to_make_ends_meet;
	VAR With_Great_Difficulty With_Difficulty Some_Difficulty;
RUN;

/* 10: Generating graphs */
PROC SGPLOT DATA=inability_with_mean;
	TITLE 'Mean Difficulty by Country';
	VBAR Country / RESPONSE=Mean_Difficulty;
RUN;