# SAP Mass Download of ABAP Download Programs in HTML/TEXT format

SAP Mass Download: The following program offers to mass download of SAP sources ( ABAP Download source code to your local PC/Mac).  
  
First, it scans the source code as well as text and documentation in order to import the most important pieces to save programs locally as HTML pages or plain Texts.  

## Create the SAP Mass ABAP Download Program

Here the different step to create a new SAP ABAP Report to perform Mass Download of ABAP codes with different criteria.  
  
(Make sure you have the requested authorizations and a SAP Development key in order to implement this SAP Report)  
  
1. Go to SE38, and create a new program with ZDTP_MASSDOWNLOAD.
2. Open the source code Mass Download 1.X.X.txt and copy/paste it into the SE38 program.
3. Activate the program. Check if it is free of error. It is ready to be executed.

## Launching the SAP ABAP Mass Download

This program allows you mass download not only ABAP sources but also:  
  
- Tables, Structures and Tables Types: that can be find in SE11 for SAP DDIC Elements that you want to download locally. It selects also the Structures extension to standard tables/structures )
- Messages Classes: ( you can manage Message Classes and Messages in the SAP Tcode SE91 )
- Functions modules: It works for both function group and function module
- XSLT Transformation: Here an other pain point of ABAP: Conversion of XML file within ABAP Code
- Classes: Select if you want to download specific ABAP OO Code ( Classes Interfaces + Classes + Methods + Class Attributes )
- ABAP Programs: back to the basic: any ABAP reports or ABAP Includes ( go to SE80 or SE38 )

Here a screenshot with all the “Objects to download” available to download ABAP source code to local.  
  
https://sap4tech.net/wp-content/uploads/2015/09/Mass_download_Object_Download-e1446840764384.png

## SAP Mass Download Output

The Mass Download program can save ABAP sources into 2 different formats:

- HTML Document ( with links between different files called in the main ABAP Program for sample) – this is my preferred one !
- Text Document ( flat format )

https://sap4tech.net/wp-content/uploads/2015/09/SAP-Mass-Download-Format-e1446840722938.png

The output destination can be set to :  
  
- SAP server: by passing a Logical File Name
- Locally: by passing File path to a local folder.
https://sap4tech.net/wp-content/uploads/2015/09/SAP-Mass-Download-Destination-e1446840747891.png

## SAP Mass Download Extra parameters

You can set extra parameters for the SAP Mass Download Programs.

For examples:

1. Setting the language to retrieve text and messages
2. Filtering by Packages
3. Downloading only Custom objects
4. Filtering on SAP Objects modified by a specific user
5. …

## Conclusion
If you are working for different SAP project, this SAP ABAP Mass Download report is very useful in order to reuse what you have already done and avoid loosing a lot of time downloading the ABAP Source Code individually file by file.
