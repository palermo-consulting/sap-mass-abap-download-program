PROGRAM zdtp_massdownload.
*======================================================================================================================
*  Mass download version 1.5.5.
*----------------------------------------------------------------------------------------------------------------------
*  PROGRAM DESCRIPTION & USE
*  Allows a user to download programs, Functions, DD definitions, etc to the presentation server.  This version searches
*  recursively for nested includes and function modules, and allows you to download the resulting code as standard text
*  or HTML web pages within a suitable directory structure.
*
*  You can either search by object name, using wildcards if you wish, or a combination of Author and object name.  If
*  you want all objects returned for a particular author then select the author name and choose the most suitable
*  radiobutton.  All objects will be returned if the fields to the right hand side of the radiobutton are left completely
*  blank.
*
*  Compatible with R/3 Enterprise and Netweaver, for older versions of SAP you will need Direct Download version 5.xx.
*  This version removes the programming limitations imposed by developing across SAP releases 3 to 4.6.
*
*  In order to be able to download files to the SAP server you must first set up a logical filepath within transaction
*  'FILE', or use an existing one.  You must also create a external operating system command in SM69 called ZDTX_MKDIR. This
*  will then be used to create any directories needed on the SAP server

*  This program is intended to allow a person to keep a visual representation of a program for backup purposes only as
*  has not been designed to allow programs to be uploaded to SAP systems.
*----------------------------------------------------------------------------------------------------------------------
*
* Author          : Copyright (C) 1998 E.G.Mellodew
* program contact : www.dalestech.com

* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
*----------------------------------------------------------------------------------------------------------------------

*----------------------------------------------------------------------------------------------------------------------
*  SAP Tables
*----------------------------------------------------------------------------------------------------------------------
TABLES: trdir, seoclass, tfdir, enlfdir, dd02l, tadiv, dd40l, transfdesc.
TYPE-POOLS: abap, seor.

*----------------------------------------------------------------------------------------------------------------------
*  Types
*----------------------------------------------------------------------------------------------------------------------
* text element structure
TYPES: ttexttable LIKE textpool.
* GUI titles
TYPES: tguititle LIKE d347t.

* Message classes
TYPES: BEGIN OF tmessage,
         arbgb LIKE t100-arbgb,
         stext LIKE t100a-stext,
         msgnr LIKE t100-msgnr,
         text  LIKE t100-text,
       END OF tmessage.

* Screen flow.
TYPES: BEGIN OF tscreenflow,
         screen LIKE d020s-dnum,
         code LIKE d022s-line,
       END OF tscreenflow.

* Holds all domain texts
TYPES: BEGIN OF tdomainstructure,
         domname TYPE domname,
         domvalue_l TYPE domvalue_l,
         domvalue_h TYPE domvalue_l,
         ddtext TYPE val_text,
       END OF tdomainstructure.

* Holds a table\structure definition
TYPES: BEGIN OF tdicttablestructure,
         fieldname LIKE dd03l-fieldname,
         position  LIKE dd03l-position,
         keyflag   LIKE dd03l-keyflag,
         rollname  LIKE dd03l-rollname,
         domname   LIKE dd03l-domname,
         datatype  LIKE dd03l-datatype,
         leng      LIKE dd03l-leng,
         lowercase TYPE lowercase,
         ddtext    LIKE dd04t-ddtext,
         idomains TYPE tdomainstructure OCCURS 0,
       END OF tdicttablestructure.

*-- Holds a table type
TYPES: BEGIN OF ttabletype,
         typename   TYPE ttypename,  " Name of table type
         rowtype    TYPE ttrowtype,  " Name of row type for table types
         ttypkind   TYPE ttypkind,   " Category of table type (range or general table type)
         range_ctyp TYPE range_ctyp, " Elem. type of LOW and HIGH components of a Ranges type
         reftype    TYPE ddreftype,  " Type of Object Referenced
         occurs     TYPE ddoccurs,   " Initial Line Number for Table Types
         ddtext     TYPE ddtext,     " Description
       END OF ttabletype.

* Holds a tables attributes + its definition
TYPES: BEGIN OF tdicttable,
         tablename    LIKE dd03l-tabname,
         tabletitle   LIKE dd02t-ddtext,
         istructure TYPE tdicttablestructure OCCURS 0,
       END OF tdicttable.

TYPES: BEGIN OF tdictfilename,
         tablename    LIKE dd03l-tabname,
         filename TYPE string,
       END OF tdictfilename.

TYPES: BEGIN OF ttransformation,
         xsltname LIKE trdir-name,
         xsltdesc LIKE tftit-stext,
         subc     LIKE trdir-subc,
       END OF ttransformation.

* Include program names
TYPES: BEGIN OF tinclude,
         includename LIKE trdir-name,
         includetitle LIKE tftit-stext,
       END OF tinclude.

* Exception class texts
TYPES: BEGIN OF tconcept,
         constname TYPE string,
         concept TYPE sotr_conc,
       END OF tconcept.

* Method
TYPES: BEGIN OF tmethod,
         cmpname(61),
         descript LIKE vseomethod-descript,
         exposure LIKE vseomethod-exposure,
         methodkey TYPE string,
       END OF tmethod.

* Interfaces
TYPES: BEGIN OF tinterface,
         interfacename LIKE vseoclass-clsname,
       END OF tinterface.

* Class
TYPES: BEGIN OF tclass,
         scanned(1),
         clsname LIKE vseoclass-clsname,
         descript LIKE vseoclass-descript,
         msg_id LIKE vseoclass-msg_id,
         exposure LIKE vseoclass-exposure,
         state LIKE vseoclass-state,
         clsfinal LIKE vseoclass-clsfinal,
         r3release LIKE vseoclass-r3release,
         imethods TYPE tmethod OCCURS 0,
         idictstruct TYPE tdicttable OCCURS 0,
         itextelements TYPE ttexttable OCCURS 0,
         imessages TYPE tmessage OCCURS 0,
         iinterfaces TYPE tinterface OCCURS 0,
         iconcepts TYPE tconcept OCCURS 0,
         itabletypes TYPE ttabletype OCCURS 0,
         itransformations TYPE ttransformation OCCURS 0,
         textelementkey TYPE string,
         publicclasskey TYPE string,
         privateclasskey TYPE string,
         protectedclasskey TYPE string,
         typesclasskey TYPE string,
         exceptionclass TYPE abap_bool,
       END OF tclass.

* function modules
TYPES: BEGIN OF tfunction,
         functionname LIKE tfdir-funcname,
         functiongroup LIKE enlfdir-area,
         includenumber LIKE tfdir-include,
         functionmaininclude LIKE tfdir-funcname,
         functiontitle LIKE tftit-stext,
         topincludename LIKE tfdir-funcname,
         progname LIKE tfdir-pname,
         programlinkname LIKE tfdir-pname,
         messageclass LIKE t100-arbgb,
         itextelements TYPE ttexttable OCCURS 0,
         iselectiontexts TYPE ttexttable OCCURS 0,
         imessages TYPE tmessage OCCURS 0,
         iincludes TYPE tinclude OCCURS 0,
         idictstruct TYPE tdicttable OCCURS 0,
         iguititle TYPE tguititle OCCURS 0,
         iscreenflow TYPE tscreenflow OCCURS 0,
         itabletypes TYPE ttabletype OCCURS 0,
         itransformations TYPE ttransformation OCCURS 0,
       END OF tfunction.

TYPES: BEGIN OF tprogram,
         progname LIKE trdir-name,
         programtitle LIKE tftit-stext,
         subc LIKE trdir-subc,
         messageclass LIKE t100-arbgb,
         imessages TYPE tmessage OCCURS 0,
         itextelements TYPE ttexttable OCCURS 0,
         iselectiontexts TYPE ttexttable OCCURS 0,
         iguititle TYPE tguititle OCCURS 0,
         iscreenflow TYPE tscreenflow OCCURS 0,
         iincludes TYPE tinclude OCCURS 0,
         idictstruct TYPE tdicttable OCCURS 0,
         itabletypes TYPE ttabletype OCCURS 0,
         itransformations TYPE ttransformation OCCURS 0,
       END OF tprogram.

*----------------------------------------------------------------------------------------------------------------------
*  Internal tables
*----------------------------------------------------------------------------------------------------------------------
*  Dictionary object
DATA: idictionary TYPE STANDARD TABLE OF tdicttable WITH HEADER LINE.
*  Dictionary objects which have previously been downloaded
DATA: idictfilename TYPE STANDARD TABLE OF tdictfilename WITH HEADER LINE.
*  Table Types
DATA: itabletypes TYPE STANDARD TABLE OF ttabletype WITH HEADER LINE.
*  Table Type objects which have previously been downloaded
DATA: itabletypefilename TYPE STANDARD TABLE OF tdictfilename WITH HEADER LINE.
* Function modules.
DATA: ifunctions TYPE STANDARD TABLE OF tfunction WITH HEADER LINE.
* Function modules used within programs.
DATA: iprogfunctions TYPE STANDARD TABLE OF tfunction WITH HEADER LINE.
* Tree display structure.
DATA: itreedisplay TYPE STANDARD TABLE OF snodetext WITH HEADER LINE.
* Message class data
DATA: imessages TYPE STANDARD TABLE OF tmessage WITH HEADER LINE.
* Holds a single message class an all of its messages
DATA: isinglemessageclass TYPE STANDARD TABLE OF tmessage WITH HEADER LINE.
* Holds program related data
DATA: iprograms TYPE STANDARD TABLE OF tprogram WITH HEADER LINE.
* Classes
DATA: iclasses TYPE STANDARD TABLE OF tclass WITH HEADER LINE.
* Table of paths created on the SAP server
DATA: iserverpaths TYPE STANDARD TABLE OF string WITH HEADER LINE.
* Table of XSL Transformations
DATA: itransformations TYPE STANDARD TABLE OF ttransformation WITH HEADER LINE.

*----------------------------------------------------------------------------------------------------------------------
*  Table prototypes
*----------------------------------------------------------------------------------------------------------------------
DATA: dumidictstructure TYPE STANDARD TABLE OF tdicttablestructure.
DATA: dumitexttab TYPE STANDARD TABLE OF ttexttable.
DATA: dumiincludes TYPE STANDARD TABLE OF tinclude.
DATA: dumihtml TYPE STANDARD TABLE OF string.
DATA: dumiheader TYPE STANDARD TABLE OF string .
DATA: dumiscreen TYPE STANDARD TABLE OF tscreenflow .
DATA: dumiguititle TYPE STANDARD TABLE OF tguititle.
DATA: dumimethods TYPE STANDARD TABLE OF tmethod.
DATA: dumiconcepts TYPE STANDARD TABLE OF tconcept.
DATA: dumiinterfaces TYPE STANDARD TABLE OF tinterface.

*----------------------------------------------------------------------------------------------------------------------
*   Global objects
*----------------------------------------------------------------------------------------------------------------------
DATA: objfile TYPE REF TO cl_gui_frontend_services.
DATA: objruntimeerror TYPE REF TO cx_root.

*----------------------------------------------------------------------------------------------------------------------
*  Constants
*----------------------------------------------------------------------------------------------------------------------
CONSTANTS: versionno TYPE string VALUE '1.5.5'.
CONSTANTS: tables TYPE string VALUE 'TABLES'.
CONSTANTS: table TYPE string VALUE 'TABLE'.
CONSTANTS: like TYPE string VALUE 'LIKE'.
CONSTANTS: type TYPE string VALUE 'TYPE'.
CONSTANTS: typerefto TYPE string VALUE 'TYPE REF TO'.
CONSTANTS: structure TYPE string VALUE 'STRUCTURE'.
CONSTANTS: lowstructure TYPE string VALUE 'structure'.
CONSTANTS: occurs TYPE string VALUE 'OCCURS'.
CONSTANTS: function TYPE string VALUE 'FUNCTION'.
CONSTANTS: callfunction TYPE string VALUE ' CALL FUNCTION'.
CONSTANTS: message TYPE string  VALUE 'MESSAGE'.
CONSTANTS: include TYPE string VALUE 'INCLUDE'.
CONSTANTS: transformation TYPE string VALUE 'TRANSFORMATION'.
CONSTANTS: lowinclude TYPE string VALUE 'include'.
CONSTANTS: destination TYPE string VALUE 'DESTINATION'.
CONSTANTS: is_table TYPE string VALUE 'T'.
CONSTANTS: is_transformation TYPE string VALUE 'X'.
CONSTANTS: is_program TYPE string VALUE 'P'.
CONSTANTS: is_screen TYPE string VALUE 'S'.
CONSTANTS: is_guititle TYPE string VALUE 'G'.
CONSTANTS: is_documentation TYPE string VALUE 'D'.
CONSTANTS: is_messageclass TYPE string VALUE 'MC'.
CONSTANTS: is_function TYPE string VALUE 'F'.
CONSTANTS: is_class TYPE string VALUE 'C'.
CONSTANTS: is_method TYPE string VALUE 'M'.
CONSTANTS: asterix TYPE string VALUE '*'.
CONSTANTS: comma TYPE string VALUE ','.
CONSTANTS: period TYPE string VALUE '.'.
CONSTANTS: dash TYPE string VALUE '-'.
CONSTANTS: true TYPE abap_bool VALUE 'X'.
CONSTANTS: false TYPE abap_bool VALUE ''.
CONSTANTS: lt TYPE string VALUE '&lt;'.
CONSTANTS: gt TYPE string VALUE '&gt;'.
CONSTANTS: unix TYPE string VALUE 'UNIX'.
CONSTANTS: non_unix TYPE string VALUE 'not UNIX'.
CONSTANTS: htmlextension TYPE string VALUE 'html'.
CONSTANTS: textextension TYPE string VALUE 'txt'.
CONSTANTS: ss_code TYPE c VALUE 'C'.
CONSTANTS: ss_table TYPE c VALUE 'T'.

*----------------------------------------------------------------------------------------------------------------------
*  Global variables
*----------------------------------------------------------------------------------------------------------------------
DATA: statusbarmessage(100).
DATA: forcedexit TYPE abap_bool VALUE false.
DATA: starttime LIKE sy-uzeit.
DATA: runtime LIKE sy-uzeit.
DATA: downloadfileextension TYPE string.
DATA: downloadfolder TYPE string.
DATA: serverslashseparator TYPE string.
DATA: frontendslashseparator TYPE string.
DATA: slashseparatortouse TYPE string.
DATA: serverfilesystem TYPE filesys_d.
DATA: serverfolder TYPE string.
DATA: frontendopsystem TYPE string.
DATA: serveropsystem TYPE string.
DATA: customernamespace TYPE string.
RANGES: soprogramname FOR trdir-name.
RANGES: soauthor FOR usr02-bname.
RANGES: sotablenames FOR dd02l-tabname.
RANGES: sotabletypenames FOR dd40l-typename.
RANGES: sofunctionname  FOR tfdir-funcname.
RANGES: soclassname FOR vseoclass-clsname.
RANGES: sofunctiongroup FOR enlfdir-area.
RANGES: soxsltname FOR tadir-obj_name.
FIELD-SYMBOLS: <wadictstruct> TYPE tdicttable.

*----------------------------------------------------------------------------------------------------------------------
*  Selection screen declaration
*----------------------------------------------------------------------------------------------------------------------
* Author
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE tblock1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) tauth.
PARAMETERS: pauth LIKE usr02-bname MEMORY ID mauth.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(36) tpmod.
PARAMETERS: pmod AS CHECKBOX.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE tblock2.
* Tables
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rtable RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(15) trtable.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tptable.
SELECT-OPTIONS: sotable FOR dd02l-tabname.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(79) ttnote.
SELECTION-SCREEN END OF LINE.

* Table Types
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rtabtype RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(15) trtabtyp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tptabtyp.
SELECT-OPTIONS: sotabtyp FOR dd40l-typename.
SELECTION-SCREEN END OF LINE.

* Message classes
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rmess RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(18) tpmes.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(18) tmname.
PARAMETERS: pmname LIKE t100-arbgb MEMORY ID mmname.
SELECTION-SCREEN END OF LINE.

* Function modules
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rfunc RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(30) trfunc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tpfname.
SELECT-OPTIONS: sofname FOR tfdir-funcname.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tfgroup.
SELECT-OPTIONS: sofgroup FOR enlfdir-area.
SELECTION-SCREEN END OF LINE.

* XSLT
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rxslt RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(30) trxslt.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tpxslt.
SELECT-OPTIONS: soxslt FOR transfdesc-xsltdesc.
SELECTION-SCREEN END OF LINE.

* Classes
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rclass RADIOBUTTON GROUP r1.
SELECTION-SCREEN COMMENT 5(30) trclass.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) tpcname.
SELECT-OPTIONS: soclass FOR seoclass-clsname.
SELECTION-SCREEN END OF LINE.

* Programs / includes
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: rprog RADIOBUTTON GROUP r1 DEFAULT 'X'.
SELECTION-SCREEN COMMENT 5(18) tprog.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 10(15) trpname.
SELECT-OPTIONS: soprog FOR trdir-name.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.
* Language
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(27) tmlang.
PARAMETERS: pmlang LIKE t100-sprsl DEFAULT 'EN'.
SELECTION-SCREEN END OF LINE.

* Package
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(24) tpack.
SELECT-OPTIONS: sopack FOR tadiv-devclass.
SELECTION-SCREEN END OF LINE.

* Customer objects
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(27) tcust.
PARAMETERS: pcust AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.

* Alt customer name range
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(27) tnrange.
PARAMETERS: pcname TYPE namespace MEMORY ID mnamespace.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b2.

* Additional things to download.
SELECTION-SCREEN: BEGIN OF BLOCK b3 WITH FRAME TITLE tblock3.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tptext.
PARAMETERS: ptext AS CHECKBOX DEFAULT 'X' MEMORY ID mtext.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tmess.
PARAMETERS: pmess AS CHECKBOX DEFAULT 'X' MEMORY ID mmess.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tttyp.
PARAMETERS: pttyp AS CHECKBOX DEFAULT 'X' MEMORY ID mttyp.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) txslt.
PARAMETERS: ptrans AS CHECKBOX DEFAULT 'X' MEMORY ID mxslt.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tpinc.
PARAMETERS: pinc AS CHECKBOX DEFAULT 'X' MEMORY ID minc.
SELECTION-SCREEN COMMENT 40(20) treci.
PARAMETERS: preci AS CHECKBOX DEFAULT 'X' MEMORY ID mreci.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tpfunc.
PARAMETERS: pfunc AS CHECKBOX DEFAULT 'X' MEMORY ID mfunc.
SELECTION-SCREEN COMMENT 40(20) trecf.
PARAMETERS: precf AS CHECKBOX DEFAULT 'X' MEMORY ID mrecf.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) trecc.
PARAMETERS: precc AS CHECKBOX DEFAULT 'X' MEMORY ID mrecc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tfdoc.
PARAMETERS: pfdoc AS CHECKBOX DEFAULT 'X' MEMORY ID mfdoc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tcdoc.
PARAMETERS: pcdoc AS CHECKBOX DEFAULT 'X' MEMORY ID mcdoc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tpscr.
PARAMETERS: pscr AS CHECKBOX DEFAULT 'X' MEMORY ID mscr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tpdict.
PARAMETERS: pdict AS CHECKBOX DEFAULT 'X' MEMORY ID mdict.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tsortt.
PARAMETERS: psortt AS CHECKBOX DEFAULT ' ' MEMORY ID msortt.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b3.

* File details
SELECTION-SCREEN: BEGIN OF BLOCK b4 WITH FRAME TITLE tblock4.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) tphtml.
PARAMETERS: phtml RADIOBUTTON GROUP g1 DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(29) tback.
PARAMETERS: pback AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) tptxt.
PARAMETERS: ptxt RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

* Download to SAP server
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(25) tserv.
PARAMETERS: pserv RADIOBUTTON GROUP g2.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 8(20) tspath.
PARAMETERS: plogical LIKE filename-fileintern MEMORY ID mlogical.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN COMMENT /28(60) tsdpath.

* Download to PC
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(25) tpc.
PARAMETERS: ppc RADIOBUTTON GROUP g2 DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 8(20) tppath.
PARAMETERS: pfolder LIKE rlgrap-filename MEMORY ID mfolder.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b4.

* Display options
SELECTION-SCREEN: BEGIN OF BLOCK b5 WITH FRAME TITLE tblock5.
* Display final report
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) trep.
PARAMETERS: prep AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.
* Display progress messages
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) tpromess.
PARAMETERS: ppromess AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b5.

*----------------------------------------------------------------------------------------------------------------------
* Display a directory picker window
*----------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR pfolder.

  DATA: objfile TYPE REF TO cl_gui_frontend_services.
  DATA: pickedfolder TYPE string.
  DATA: initialfolder TYPE string.

  IF sy-batch IS INITIAL.
    CREATE OBJECT objfile.

    IF NOT pfolder IS INITIAL.
      initialfolder = pfolder.
    ELSE.
      objfile->get_temp_directory( CHANGING temp_dir = initialfolder
                                   EXCEPTIONS cntl_error = 1
                                             error_no_gui = 2
                                             not_supported_by_gui = 3 ).
    ENDIF.

    objfile->directory_browse( EXPORTING initial_folder = initialfolder
                               CHANGING selected_folder = pickedfolder
                               EXCEPTIONS cntl_error = 1
                                          error_no_gui = 2
                                          not_supported_by_gui = 3 ).

    IF sy-subrc = 0.
      pfolder = pickedfolder.
    ELSE.
      WRITE: / 'An error has occured picking a folder'.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN.
*----------------------------------------------------------------------------------------------------------------------
  CASE 'X'.
    WHEN ppc.
      IF pfolder IS INITIAL.
*       User must enter a path to save to
        MESSAGE e000(oo) WITH 'You must enter a file path'.
      ENDIF.

    WHEN pserv.
      IF plogical IS INITIAL.
*       User must enter a logical path to save to
        MESSAGE e000(oo) WITH 'You must enter a logical file name'.
      ENDIF.
  ENDCASE.

*----------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON plogical.
*----------------------------------------------------------------------------------------------------------------------
  IF NOT pserv IS INITIAL.
    CALL FUNCTION 'FILE_GET_NAME'
      EXPORTING
        logical_filename = plogical
      IMPORTING
        file_name        = serverfolder
      EXCEPTIONS
        file_not_found   = 1
        OTHERS           = 2.
    IF sy-subrc = 0.
      IF serverfolder IS INITIAL.
        MESSAGE e000(oo) WITH 'No file path returned from logical filename'.
      ELSE.
*       Path to display on the selection screen
        tsdpath = serverfolder.
*       Remove the trailing slash off the path as the subroutine buildFilename will add an extra one
        SHIFT serverfolder RIGHT DELETING TRAILING serverslashseparator.
        SHIFT serverfolder LEFT DELETING LEADING space.
      ENDIF.
    ELSE.
      MESSAGE e000(oo) WITH 'Logical filename does not exist'.
    ENDIF.
  ENDIF.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soprog-low.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'PROG'
      object_name           = soprog-low
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = soprog-low
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soprog-high.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'PROG'
      object_name           = soprog-high
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = soprog-high
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soxslt-low.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'XSLT'
      object_name           = soxslt-low
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = soxslt-low
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soxslt-high.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'XSLT'
      object_name           = soxslt-high
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = soxslt-high
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soclass-low.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'F4_DD_ALLTYPES'
    EXPORTING
      object               = soclass-low
      suppress_selection   = 'X'
      display_only         = ''
      only_types_for_clifs = 'X'
    IMPORTING
      result               = soclass-low.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR soclass-high.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'F4_DD_ALLTYPES'
    EXPORTING
      object               = soclass-high
      suppress_selection   = 'X'
      display_only         = ''
      only_types_for_clifs = 'X'
    IMPORTING
      result               = soclass-high.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR sofname-low.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'FUNC'
      object_name           = sofname-low
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = sofname-low
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR sofname-high.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'FUNC'
      object_name           = sofname-high
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = sofname-high
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR sofgroup-low.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'FUGR'
      object_name           = sofgroup-low
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = sofgroup-low
    EXCEPTIONS
      cancel                = 1.

* ---------------------------------------------------------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR sofgroup-high.
* ---------------------------------------------------------------------------------------------------------------------
  CALL FUNCTION 'REPOSITORY_INFO_SYSTEM_F4'
    EXPORTING
      object_type           = 'FUGR'
      object_name           = sofgroup-high
      suppress_selection    = 'X'
      use_alv_grid          = ''
      without_personal_list = ''
    IMPORTING
      object_name_selected  = sofgroup-high
    EXCEPTIONS
      cancel                = 1.

*----------------------------------------------------------------------------------------------------------------------
* initialisation
*----------------------------------------------------------------------------------------------------------------------
INITIALIZATION.
* Parameter screen texts.
  tblock1 = 'Author (Optional)'.
  tblock2 = 'Objects to download'.
  tblock3 = 'Additional downloads for programs, function modules and classes'.
  tblock4 = 'Download parameters'.
  tblock5 = 'Display options'.
  tauth   = 'Author name'.
  tpmod   = 'Include programs modified by author'.
  tcust   = 'Only customer objects'.
  tnrange = 'Alt customer name range'.
  trtable = 'Tables / Structures'.
  trtabtyp = 'Table types'.
  tptable = 'Table name'.
  ttnote  = 'Note: tables are stored under the username of the last person who modified them'.
  trfunc  = 'Function modules'.
  tpfname = 'Function name'.
  tfgroup = 'Function group'.
  trclass  = 'Classes'.
  tpcname = 'Class name'.
  tmess   = 'Message class'.
  tmname  = 'Class name'.
  tmlang  = 'Language'.
  tprog   = 'Programs'.
  trpname = 'Program name'.
  tpack   = 'Package'.
  tptxt   = 'Text document'.
  tphtml  = 'HTML document'.
  tback   = 'Include background colour'.
  tptext  = 'Text elements'.
  tpinc   = 'Include programs'.
  treci   = 'Recursive search'.
  tppath  = 'File path'.
  tspath  = 'Logical file name'.
  tpmes   = 'Message classes'.
  tpfunc  = 'Function modules'.
  tfdoc    = 'Function module documentation'.
  tcdoc    = 'Class documentation'.
  trecf   = 'Recursive search'.
  trecc   = 'Class recursive search'.
  tpscr   = 'Screens'.
  tpdict  = 'Dictionary structures'.
  tsortt  = 'Sort table fields alphabetically'.
  tserv   = 'Download to server'.
  tpc     = 'Download to PC'.
  trep    = 'Display download report'.
  tpromess  = 'Display progress messages'.
  trxslt     = 'Transformations'.
  tpxslt    = 'XSLT Name'.
  tttyp = 'Table Types'.
  txslt = 'Transformation'.

* Determine the frontend operating system type.
  IF sy-batch IS INITIAL.
    PERFORM determinefrontendopsystem USING frontendslashseparator frontendopsystem.
  ENDIF.
  PERFORM determineserveropsystem USING serverslashseparator serverfilesystem serveropsystem.

* Determine if the external command exists.  If it doesn't then disable the server input field
  PERFORM findexternalcommand USING serverfilesystem.

*----------------------------------------------------------------------------------------------------------------------
START-OF-SELECTION.
*----------------------------------------------------------------------------------------------------------------------
  PERFORM checkcomboboxes.
  PERFORM fillselectionranges.
  starttime = sy-uzeit.

* Don't display status messages if we are running in the background
  IF NOT sy-batch IS INITIAL.
    ppromess = ''.
  ENDIF.

* Fool the HTML routines to stop them hyperlinking anything with a space in them
  IF pcname IS INITIAL.
    customernamespace  = '^'.
  ELSE.
    customernamespace = pcname.
  ENDIF.

* Set the file extension and output type of the file
  IF ptxt IS INITIAL.
    downloadfileextension = htmlextension.
  ELSE.
    downloadfileextension = textextension.
  ENDIF.

* Determine which operating slash and download directory to use
  CASE 'X'.
    WHEN ppc.
      slashseparatortouse = frontendslashseparator.
      downloadfolder = pfolder.
    WHEN pserv.
      slashseparatortouse = serverslashseparator.
      downloadfolder = serverfolder.
  ENDCASE.

* Main program flow.
  CASE 'X'.
*   Select tables
    WHEN rtable.
      PERFORM retrievetables USING idictionary[]
                                   sotablenames[]
                                   soauthor[]
                                   sopack[].

    WHEN rtabtype.
      PERFORM retrievetabletypes USING itabletypes[]
                                       sotabletypenames[]
                                       soauthor[]
                                       sopack[].

*   Select message classes tables
    WHEN rmess.
      PERFORM retrievemessageclass USING imessages[]
                                         soauthor[]      "Author
                                         pmname          "Message class name
                                         pmlang          "Message class language
                                         pmod            "Modified by author
                                         sopack[].       "Package

*   Select function modules
    WHEN rfunc.
      PERFORM retrievefunctions USING sofunctionname[]   "Function name
                                      sofunctiongroup[]  "Function group
                                      ifunctions[]       "Found functions
                                      soauthor[]         "Author
                                      ptext              "Get text elements
                                      pscr               "Get screens
                                      pcust              "Customer data only
                                      customernamespace  "Customer name range
                                      sopack[].             "Package

*       Find Dict structures, messages, functions, includes etc.
      PERFORM scanforadditionalfuncstuff USING ifunctions[]
                                               preci                   "Search for includes recursively
                                               precf                   "Search for functions recursively
                                               pinc                    "Search for includes
                                               pfunc                   "Search for functions
                                               pdict                   "search for dictionary objects
                                               pmess                   "Search for messages
                                               ptrans                  "Search for transformations
                                               pcust                   "Customer data only
                                               customernamespace.      "Customer name range

*   Select Classes
    WHEN rclass.
      PERFORM retrieveclasses USING iclasses[]
                                    ifunctions[]
                                    soclassname[]       "Class name
                                    soauthor[]          "Author
                                    customernamespace   "Customer name range
                                    pmod                "Also modified by author
                                    pcust               "Customer object only
                                    pmess               "Find messages
                                    ptext               "Text Elements
                                    pdict               "Dictionary structures
                                    pfunc               "Get functions
                                    pinc                "Get includes
                                    ptrans
                                    precf               "Search recursively for functions
                                    preci               "Search recursively for includes
                                    precc               "Search recursively for classes
                                    pmlang              "Language
                                    sopack[].           "Package

      LOOP AT ifunctions.
*       Find Dict structures, messages, functions, includes etc.
        PERFORM scanforadditionalfuncstuff USING ifunctions[]
                                                 preci                   "Search for includes recursively
                                                 precf                   "Search for functions recursively
                                                 pinc                    "Search for includes
                                                 pfunc                   "Search for functions
                                                 pdict                   "search for dictionary objects
                                                 pmess                   "Search for messages
                                                 ptrans                  "Search for transformations
                                                 pcust                   "Customer data only
                                                 customernamespace.      "Customer name range
      ENDLOOP.

*   Select programs
    WHEN rprog.
      PERFORM retrieveprograms USING iprograms[]
                                     iprogfunctions[]
                                     soprogramname[]    "Program name
                                     soauthor[]         "Author
                                     customernamespace  "Customer name range
                                     pmod               "Also modified by author
                                     pcust              "Customer object only
                                     pmess              "Find messages
                                     ptext              "Text Elements
                                     pdict              "Dictionay structures
                                     pfunc              "Get functions
                                     pinc               "Get includes
                                     pscr               "Get screens
                                     ptrans             "Get Transformations
                                     precf              "Search recursively for functions
                                     preci              "Search recursively for includes
                                     sopack[].             "Package

    WHEN rxslt.
      PERFORM retrievexslt USING itransformations[]
                                 soxsltname[]           "XSL Transformation name
                                 soauthor[]             "Author
                                 customernamespace      "Customer name range
                                 pmod                   "Also modified by author
                                 pcust                  "Customer object only
                                 sopack[].              "Package

  ENDCASE.

*----------------------------------------------------------------------------------------------------------------------
END-OF-SELECTION.
*----------------------------------------------------------------------------------------------------------------------
  IF forcedexit = 0.
*   Decide what to download
    CASE 'X'.
*     Download tables
      WHEN rtable.
        IF NOT ( idictionary[] IS INITIAL ).
          PERFORM downloadddstructures USING idictionary[]
                                             idictfilename[]
                                             downloadfolder
                                             htmlextension
                                             space
                                             psortt
                                             slashseparatortouse
                                             pserv
                                             ppromess
                                             serverfilesystem
                                             pback.
        ENDIF.

      WHEN rtabtype.
        IF NOT ( itabletypes[] IS INITIAL ).
          PERFORM downloadddtabletypes USING itabletypes[]
                                             itabletypefilename[]
                                             downloadfolder
                                             htmlextension
                                             space
                                             psortt
                                             slashseparatortouse
                                             pserv
                                             ppromess
                                             serverfilesystem
                                             pback.
        ENDIF.

*     Download message class
      WHEN rmess.
        IF NOT ( imessages[] IS INITIAL ).
          SORT imessages ASCENDING BY arbgb msgnr.
          LOOP AT imessages.
            APPEND imessages TO isinglemessageclass.
            AT END OF arbgb.
              PERFORM downloadmessageclass USING isinglemessageclass[]
                                                 imessages-arbgb
                                                 downloadfolder
                                                 downloadfileextension
                                                 phtml
                                                 space
                                                 customernamespace
                                                 pinc
                                                 pdict
                                                 pmess
                                                 slashseparatortouse
                                                 pserv
                                                 ppromess
                                                 serverfilesystem
                                                 pback.
              CLEAR isinglemessageclass[].
            ENDAT.
          ENDLOOP.
        ENDIF.

*     Download functions
      WHEN rfunc.
        IF NOT ( ifunctions[] IS INITIAL ).
          PERFORM downloadfunctions USING ifunctions[]
                                          idictfilename[]
                                          itabletypefilename[]
                                          downloadfolder
                                          downloadfileextension
                                          space
                                          pfdoc
                                          phtml
                                          customernamespace
                                          pinc
                                          pdict
                                          textextension
                                          htmlextension
                                          psortt
                                          slashseparatortouse
                                          pserv
                                          ppromess
                                          serverfilesystem
                                          pback.
        ENDIF.

*     Download Classes
      WHEN rclass.
        IF NOT ( iclasses[] IS INITIAL ).
          PERFORM downloadclasses USING iclasses[]
                                        ifunctions[]
                                        idictfilename[]
                                        itabletypefilename[]
                                        downloadfolder
                                        downloadfileextension
                                        htmlextension
                                        textextension
                                        phtml
                                        customernamespace
                                        pinc
                                        pdict
                                        pcdoc
                                        psortt
                                        slashseparatortouse
                                        pserv
                                        ppromess
                                        serverfilesystem
                                        pback.
        ENDIF.

*     Download programs
      WHEN rprog.
        IF NOT ( iprograms[] IS INITIAL ).
          PERFORM downloadprograms USING iprograms[]
                                         iprogfunctions[]
                                         idictfilename[]
                                         itabletypefilename[]
                                         downloadfolder
                                         downloadfileextension
                                         htmlextension
                                         textextension
                                         phtml
                                         customernamespace
                                         pinc
                                         pdict
                                         '' "Documentation
                                         psortt
                                         slashseparatortouse
                                         pserv
                                         ppromess
                                         serverfilesystem
                                         pback.
        ENDIF.

      WHEN rxslt.
        IF NOT ( itransformations[] IS INITIAL ).
          PERFORM downloadxslt USING itransformations[]
                                     downloadfolder
                                     downloadfileextension
                                     htmlextension
                                     textextension
                                     phtml
                                     customernamespace
                                     slashseparatortouse
                                     pserv
                                     space
                                     ppromess
                                     serverfilesystem
                                     pback.
        ENDIF.
    ENDCASE.

*   Free all the memory IDs we may have built up in the program
*   Free up any memory used for caching HTML versions of objects
    PERFORM freememory USING iprograms[]
                             ifunctions[]
                             iprogfunctions[]
                             idictionary[]
                             itabletypes[]
                             itransformations[].

    IF NOT prep IS INITIAL.
      GET TIME.
      runtime = sy-uzeit - starttime.

      CASE 'X'.
        WHEN rtable.
          PERFORM filltreenodetables USING idictionary[]
                                           itreedisplay[]
                                           runtime.
        WHEN rtabtype.
          PERFORM filltreenodetabletypes USING itabletypes[]
                                               itreedisplay[]
                                               runtime.

        WHEN rmess.
          PERFORM filltreenodemessages USING imessages[]
                                             itreedisplay[]
                                             runtime.


        WHEN rfunc.
          PERFORM filltreenodefunctions USING ifunctions[]
                                              itreedisplay[]
                                              runtime.

        WHEN rclass.
          PERFORM filltreenodeclasses USING iclasses[]
                                            ifunctions[]
                                            itreedisplay[]
                                            runtime.

        WHEN rprog.
          PERFORM filltreenodeprograms USING iprograms[]
                                             iprogfunctions[]
                                             itreedisplay[]
                                             runtime.

        WHEN rxslt.
          PERFORM filltreenodexslt USING itransformations[]
                                         itreedisplay[]
                                         runtime.
      ENDCASE.

      IF NOT ( itreedisplay[] IS INITIAL ).
        PERFORM displaytree USING itreedisplay[].
      ELSE.
        statusbarmessage = 'No items found matching selection criteria'.
        PERFORM displaystatus USING statusbarmessage 2.
      ENDIF.
    ENDIF.
  ENDIF.

* Clear out all the internal tables
  CLEAR iprograms[].
  CLEAR ifunctions[].
  CLEAR iclasses[].
  CLEAR iprogfunctions[].
  CLEAR imessages[].
  CLEAR idictionary[].
  CLEAR idictfilename[].
  CLEAR itabletypefilename[].
  CLEAR itransformations[].
  CLEAR itabletypes[].

*--- Memory IDs
* User name
  SET PARAMETER ID 'MAUTH' FIELD pauth.
* Message class
  SET PARAMETER ID 'MMNAME' FIELD pmname.
* Customer namespace
  SET PARAMETER ID 'MNAMESPACE' FIELD pcname.
* Folder
  SET PARAMETER ID 'MFOLDER' FIELD pfolder.
* Logical filepath
  SET PARAMETER ID 'MLOGICAL' FIELD plogical.
* Text element checkbox
  SET PARAMETER ID 'MTEXT' FIELD ptext.
* Messages checkbox
  SET PARAMETER ID 'MMESS' FIELD pmess.
* Includes checkbox
  SET PARAMETER ID 'MINC' FIELD pinc.
* Recursive includes checkbox.
  SET PARAMETER ID 'MRECI' FIELD preci.
* Functions checkbox
  SET PARAMETER ID 'MFUNC' FIELD pfunc.
* Recursive functions checkbox
  SET PARAMETER ID 'MRECF' FIELD precf.
* Recursive classes checkbox
  SET PARAMETER ID 'MRECF' FIELD precc.
* Function module documentation checkbox
  SET PARAMETER ID 'MFDOC' FIELD pfdoc.
* Class documentation checkbox
  SET PARAMETER ID 'MCDOC' FIELD pcdoc.
* Screens checkbox
  SET PARAMETER ID 'MSCR' FIELD pscr.
* Dictionary checkbox
  SET PARAMETER ID 'MDICT' FIELD pdict.
* Sort table ascending checkBox
  SET PARAMETER ID 'MSORTT' FIELD psortt.
* Table Types checkbox
  SET PARAMETER ID 'MTTYP' FIELD pttyp.
* XSLT checkbox
  SET PARAMETER ID 'MXSLT' FIELD ptrans.


***********************************************************************************************************************
***************************************************SUBROUTINES*********************************************************
***********************************************************************************************************************

*----------------------------------------------------------------------------------------------------------------------
*  free memory...
*----------------------------------------------------------------------------------------------------------------------
FORM freememory USING ilocprograms LIKE iprograms[]
                      ilocfunctions LIKE ifunctions[]
                      ilocprogfunctions LIKE iprogfunctions[]
                      ilocdictionary LIKE idictionary[]
                      iloctabletypes LIKE itabletypes[]
                      iloctransformation LIKE itransformations[] .

  FIELD-SYMBOLS: <wafunction> LIKE LINE OF ilocfunctions.
  FIELD-SYMBOLS: <waprogram> LIKE LINE OF ilocprograms.
  FIELD-SYMBOLS: <wadictstruct> TYPE tdicttable.
  FIELD-SYMBOLS: <watabletypestruct> LIKE LINE OF iloctabletypes.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.

  LOOP AT ilocfunctions ASSIGNING <wafunction>.
    LOOP AT <wafunction>-idictstruct ASSIGNING <wadictstruct>.
      FREE MEMORY ID <wadictstruct>-tablename.
    ENDLOOP.
  ENDLOOP.

  LOOP AT ilocprogfunctions ASSIGNING <wafunction>.
    LOOP AT <wafunction>-idictstruct ASSIGNING <wadictstruct>.
      FREE MEMORY ID <wadictstruct>-tablename.
    ENDLOOP.
  ENDLOOP.

  LOOP AT ilocprograms ASSIGNING <waprogram>.
    LOOP AT <waprogram>-idictstruct ASSIGNING <wadictstruct>.
      FREE MEMORY ID <wadictstruct>-tablename.
    ENDLOOP.
  ENDLOOP.

  LOOP AT ilocdictionary ASSIGNING <wadictstruct>.
    FREE MEMORY ID <wadictstruct>-tablename.
  ENDLOOP.

  LOOP AT iloctabletypes ASSIGNING <watabletypestruct>.
    FREE MEMORY ID <watabletypestruct>-typename.
  ENDLOOP.

  LOOP AT iloctransformation ASSIGNING <watransformation>.
    FREE MEMORY ID <watransformation>-xsltname.
  ENDLOOP.
ENDFORM.                    "freeMemory

*----------------------------------------------------------------------------------------------------------------------
*  checkComboBoxes...  Check input parameters
*----------------------------------------------------------------------------------------------------------------------
FORM checkcomboboxes.

  IF pauth IS INITIAL.
    IF sopack[] IS INITIAL.
      CASE 'X'.
        WHEN rtable.
          IF sotable[] IS INITIAL.
            statusbarmessage = 'You must enter either a table name or author.'.
          ENDIF.
        WHEN rfunc.
          IF ( sofname[] IS INITIAL ) AND ( sofgroup[] IS INITIAL ).
            IF sofname[] IS INITIAL.
              statusbarmessage = 'You must enter either a function name or author.'.
            ELSE.
              IF sofgroup[] IS INITIAL.
                statusbarmessage = 'You must enter either a function group, or an author name.'.
              ENDIF.
            ENDIF.
          ENDIF.
        WHEN rprog.
          IF soprog[] IS INITIAL.
            statusbarmessage = 'You must enter either a program name or author name.'.
          ENDIF.
      ENDCASE.
    ENDIF.
  ELSE.
*   Check the user name of the person objects are to be downloaded for
    IF pauth = 'SAP*' OR pauth = 'SAP'.
      statusbarmessage = 'Sorry cannot download all objects for SAP standard user'.
    ENDIF.
  ENDIF.

  IF NOT statusbarmessage IS INITIAL.
    PERFORM displaystatus USING statusbarmessage 3.
    forcedexit = 1.
    STOP.
  ENDIF.
ENDFORM.                                                                                "checkComboBoxes

*----------------------------------------------------------------------------------------------------------------------
* fillSelectionRanges...      for selection routines
*----------------------------------------------------------------------------------------------------------------------
FORM fillselectionranges.

  DATA: strlength TYPE i.

  strlength = strlen( pcname ).

  IF NOT pauth IS INITIAL.
    soauthor-sign = 'I'.
    soauthor-option = 'EQ'.
    soauthor-low = pauth.
    APPEND soauthor.
  ENDIF.

* Tables
  IF NOT sotable IS INITIAL.
    sotablenames[] = sotable[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT sotablenames.
        IF sotablenames-low+0(strlength) <> pcname.
          CONCATENATE pcname sotablenames-low INTO sotablenames-low.
        ENDIF.

        IF sotablenames-high+0(strlength) <> pcname.
          CONCATENATE pcname sotablenames-high INTO sotablenames-high.
        ENDIF.

        MODIFY sotablenames.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Function names
  IF NOT sofname IS INITIAL.
    sofunctionname[] = sofname[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT sofunctionname.
        IF sofunctionname-low+0(strlength) <> pcname.
          CONCATENATE pcname sofunctionname-low INTO sofunctionname-low.
        ENDIF.

        IF sofunctionname-high+0(strlength) <> pcname.
          CONCATENATE pcname sofunctionname-high INTO sofunctionname-high.
        ENDIF.

        MODIFY sofunctionname.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Table Types
  IF NOT sotabtyp IS INITIAL.
    sotabletypenames[] = sotabtyp[].

*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT sotabletypenames.
        IF sotabletypenames-low+0(strlength) <> pcname.
          CONCATENATE pcname sotabletypenames-low INTO sotabletypenames-low.
        ENDIF.

        IF sotablenames-high+0(strlength) <> pcname.
          CONCATENATE pcname sotabletypenames-high INTO sotabletypenames-high.
        ENDIF.

        MODIFY sotabletypenames.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Function group
  IF NOT sofgroup IS INITIAL.
    sofunctiongroup[] = sofgroup[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT sofunctionname.
        IF sofunctiongroup-low+0(strlength) <> pcname.
          CONCATENATE pcname sofunctiongroup-low INTO sofunctiongroup-low.
        ENDIF.

        IF sofunctiongroup-high+0(strlength) <> pcname.
          CONCATENATE pcname sofunctiongroup-high INTO sofunctiongroup-high.
        ENDIF.

        MODIFY sofunctiongroup.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Class names
  IF NOT soclass IS INITIAL.
    soclassname[] = soclass[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT soclassname.
        IF soclassname-low+0(strlength) <> pcname.
          CONCATENATE pcname soclassname-low INTO soclassname-low.
        ENDIF.

        IF soclassname-high+0(strlength) <> pcname.
          CONCATENATE pcname soclassname-high INTO soclassname-high.
        ENDIF.

        MODIFY soclassname.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Program names
  IF NOT soprog IS INITIAL.
    soprogramname[] = soprog[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT soprogramname.
        IF soprogramname-low+0(strlength) <> pcname.
          CONCATENATE pcname soprogramname-low INTO soprogramname-low.
        ENDIF.

        IF soprogramname-high+0(strlength) <> pcname.
          CONCATENATE pcname soprogramname-high INTO soprogramname-high.
        ENDIF.

        MODIFY soprogramname.
      ENDLOOP.
    ENDIF.
  ENDIF.

* XSLT names
  IF NOT soxslt IS INITIAL.
    soxsltname[] = soxslt[].
*   Add in the customer namespace if we need to
    IF NOT pcname IS INITIAL.
      LOOP AT soxsltname.
        IF soxsltname-low+0(strlength) <> pcname.
          CONCATENATE pcname soxsltname-low INTO soxsltname-low.
        ENDIF.

        IF soxsltname-high+0(strlength) <> pcname.
          CONCATENATE pcname soxsltname-high INTO soxsltname-high.
        ENDIF.

        MODIFY soxsltname.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.                                                                                          " fillSelectionRanges

*----------------------------------------------------------------------------------------------------------------------
*  retrieveTables...             Search for tables in dictionary
*----------------------------------------------------------------------------------------------------------------------
FORM retrievetables USING ilocdictstructure LIKE idictionary[]
                          sotable LIKE sotable[]
                          soauthor LIKE soauthor[]
                          value(solocpackage) LIKE sopack[].

  DATA: idictstructure TYPE STANDARD TABLE OF tdicttable.
  DATA: wadictstructure TYPE tdicttable.

  SELECT a~tabname AS tablename
         INTO CORRESPONDING FIELDS OF TABLE idictstructure
         FROM dd02l AS a
         INNER JOIN tadir AS b
           ON a~tabname = b~obj_name
         WHERE a~tabname IN sotable
           AND a~tabclass <> 'CLUSTER'
           AND a~tabclass <> 'POOL'
           AND a~tabclass <> 'VIEW'
           AND a~as4user IN soauthor
           AND a~as4local = 'A'
           AND b~pgmid = 'R3TR'
           AND b~object = 'TABL'
           AND b~devclass IN solocpackage[].

  LOOP AT idictstructure INTO wadictstructure.
    PERFORM findtabledescription USING wadictstructure-tablename
                                       wadictstructure-tabletitle.

    PERFORM findtabledefinition USING wadictstructure-tablename
                                      wadictstructure-istructure[].

    APPEND wadictstructure TO ilocdictstructure.
    CLEAR wadictstructure.
  ENDLOOP.
ENDFORM.                                                                                                "retrieveTables

*----------------------------------------------------------------------------------------------------------------------
*  retrieveTableTypes
*----------------------------------------------------------------------------------------------------------------------
FORM retrievetabletypes  USING iloctabletypes      LIKE itabletypes[]
                               sotabletypenames    LIKE sotable[]
                               soauthor            LIKE soauthor[]
                               value(solocpackage) LIKE sopack[].

  SELECT *
         INTO CORRESPONDING FIELDS OF TABLE iloctabletypes
         FROM dd40l AS a
         INNER JOIN dd40t AS t
            ON a~typename = t~typename
         INNER JOIN tadir AS b
           ON a~typename = b~obj_name
         WHERE a~typename IN sotabletypenames
           AND t~ddlanguage EQ sy-langu
           AND a~as4user IN soauthor
           AND a~as4local = 'A'
           AND b~pgmid = 'R3TR'
           AND b~object = 'TTYP'
           AND b~devclass IN solocpackage[].

ENDFORM.                                                                                          " RETRIEVETABLETYPES

*-------------------------------------------------------------------------------------------------------
*  retrieveXSLT...
*-------------------------------------------------------------------------------------------------------
FORM retrievexslt USING iloctransformations LIKE itransformations[]
                        rangexslt   LIKE soxsltname[]
                        rangeauthor LIKE soauthor[]
                        value(custnamerange)
                        value(alsomodifiedbyauthor)
                        value(customerprogsonly)
                        value(solocpackage) LIKE sopack[].

  DATA: warangexslt LIKE LINE OF rangexslt.

  IF rangexslt[] IS INITIAL.
*   We are finding all programs by an author
    PERFORM findallxsltforauthor USING iloctransformations[]
                                       rangexslt[]
                                       rangeauthor[]
                                       custnamerange
                                       alsomodifiedbyauthor
                                       customerprogsonly
                                       solocpackage[].
  ELSE.
    READ TABLE rangexslt INDEX 1 INTO warangexslt.
    IF warangexslt-low CS asterix.
      PERFORM findxsltbywildcard USING iloctransformations[]
                                       rangexslt[]
                                       rangeauthor[]
                                       custnamerange
                                       customerprogsonly
                                       solocpackage[].
    ELSE.
      PERFORM checkxsltdoesexist USING iloctransformations[]
                                       rangexslt[].
    ENDIF.
  ENDIF.
ENDFORM.                                                                               "retrieveXSLT

*----------------------------------------------------------------------------------------------------------------------
*  findTableDescription...  Search for table description in dictionary
*----------------------------------------------------------------------------------------------------------------------
FORM findtabledescription USING value(tablename)
                                      tabledescription.

  SELECT SINGLE ddtext
                FROM dd02t
                INTO tabledescription
                WHERE tabname = tablename
                 AND ddlanguage = pmlang.
ENDFORM.                                                                                          "findTableDescription

*----------------------------------------------------------------------------------------------------------------------
*  findTableDefinition... Find the structure of a table from the SAP database.
*----------------------------------------------------------------------------------------------------------------------
FORM findtabledefinition USING value(tablename)
                               idictstruct LIKE dumidictstructure[].

  DATA gotstate LIKE dcobjif-gotstate.
  DATA: definition TYPE STANDARD TABLE OF dd03p WITH HEADER LINE.
  DATA: idomaindataa TYPE STANDARD TABLE OF dd07v WITH HEADER LINE.
  DATA: idomaindatan TYPE STANDARD TABLE OF dd07v WITH HEADER LINE.
  DATA: wadictstruct TYPE tdicttablestructure.
  DATA: wadomainstruct TYPE tdomainstructure.
  DATA: wadd02v_n TYPE dd02v.

  CLEAR idictstruct[].

  CALL FUNCTION 'DD_INT_TABL_GET'
    EXPORTING
      tabname        = tablename
      langu          = pmlang
    IMPORTING
      gotstate       = gotstate
      dd02v_n        = wadd02v_n
    TABLES
      dd03p_n        = definition
    EXCEPTIONS
      internal_error = 1.

  IF sy-subrc = 0 AND NOT wadd02v_n IS INITIAL.
    CALL FUNCTION 'DD_TABL_EXPAND'
      EXPORTING
        dd02v_wa          = wadd02v_n
        mode              = 46
        prid              = 0
      TABLES
        dd03p_tab         = definition
      EXCEPTIONS
        illegal_parameter = 1.
  ENDIF.

  IF sy-subrc = 0 AND gotstate = 'A'.
    LOOP AT definition.
      MOVE-CORRESPONDING definition TO wadictstruct.
      PERFORM removeleadingzeros CHANGING wadictstruct-position.
      PERFORM removeleadingzeros CHANGING wadictstruct-leng.

*     Add any domain data
      CALL FUNCTION 'DD_DOMA_GET'
        EXPORTING
          domain_name   = definition-domname
          get_state     = 'M  '
          langu         = pmlang
*         prid          = 0
          withtext      = 'X'
        TABLES
          dd07v_tab_a   = idomaindataa
          dd07v_tab_n   = idomaindatan
        EXCEPTIONS
          illegal_value = 1
          op_failure    = 2.

      LOOP AT idomaindataa.
        MOVE-CORRESPONDING idomaindataa TO wadomainstruct.
        APPEND wadomainstruct TO wadictstruct-idomains.
      ENDLOOP.

      CLEAR idomaindataa[].
      APPEND wadictstruct TO idictstruct.
      CLEAR wadictstruct.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                                           "findTableDefinition

*----------------------------------------------------------------------------------------------------------------------
*  retrieveMessageClass...   Retrieve a message class from the SAP database
*----------------------------------------------------------------------------------------------------------------------
FORM retrievemessageclass USING ilocmessages LIKE imessages[]
                                rangeauthor LIKE soauthor[]
                                value(messageclassname)
                                value(messageclasslang)
                                value(modifiedby)
                                value(solocpackage) LIKE sopack[].

  DATA: wamessage TYPE tmessage.
  DATA: imclasses TYPE STANDARD TABLE OF arbgb.


  IF NOT messageclassname IS INITIAL.
*   Check to see if the message class exists in the package
    IF NOT solocpackage[] IS INITIAL.
      SELECT obj_name AS arbgb
             INTO TABLE imclasses
             FROM tadir
             WHERE pgmid = 'R3TR'
               AND object = 'MSAG'
               AND devclass IN solocpackage.
    ENDIF.

    REPLACE '*' WITH '%' INTO messageclassname.
    IF imclasses[] IS INITIAL.
      SELECT t100~arbgb
             t100~text
             t100~msgnr
             t100a~stext
             APPENDING CORRESPONDING FIELDS OF TABLE ilocmessages
             FROM t100
             INNER JOIN t100a
               ON t100a~arbgb = t100~arbgb
             WHERE t100a~masterlang = messageclasslang
               AND t100~sprsl = messageclasslang
               AND t100~arbgb LIKE messageclassname
               AND t100a~respuser IN rangeauthor[].
    ELSE.
      SELECT t100~arbgb
             t100~text
             t100~msgnr
             t100a~stext
             APPENDING CORRESPONDING FIELDS OF TABLE ilocmessages
             FROM t100
             INNER JOIN t100a
               ON t100a~arbgb = t100~arbgb
             FOR ALL ENTRIES IN imclasses
               WHERE t100~sprsl = messageclasslang
               AND ( t100~arbgb LIKE messageclassname AND t100~arbgb = imclasses-table_line )
               AND t100a~masterlang = messageclasslang
               AND t100a~respuser IN rangeauthor[].
    ENDIF.
  ELSE.
    IF modifiedby IS INITIAL.
*       Select by author
      SELECT t100~arbgb                                "#EC CI_BUFFJOIN
             t100~msgnr
             t100~text
             t100a~stext
             APPENDING CORRESPONDING FIELDS OF TABLE ilocmessages
             FROM t100
             INNER JOIN t100a
               ON t100a~arbgb = t100~arbgb
             INNER JOIN tadir
               ON t100~arbgb = tadir~obj_name
             WHERE t100a~masterlang = messageclasslang
               AND t100a~respuser IN rangeauthor[]
               AND tadir~pgmid = 'R3TR'
               AND tadir~object = 'MSAG'
               AND tadir~devclass IN solocpackage[].

    ELSE.
*     Select also by the last person who modified the message class
      SELECT t100~arbgb                                "#EC CI_BUFFJOIN
             t100~msgnr
             t100~text
             t100a~stext
             APPENDING CORRESPONDING FIELDS OF TABLE ilocmessages
             FROM t100
             INNER JOIN t100a
               ON t100a~arbgb = t100~arbgb
             INNER JOIN tadir
               ON t100~arbgb = tadir~obj_name
             WHERE t100a~masterlang = messageclasslang
               AND t100a~respuser IN rangeauthor[]
               AND t100a~lastuser IN rangeauthor[]
               AND tadir~pgmid = 'R3TR'
               AND tadir~object = 'MSAG'
               AND tadir~devclass IN solocpackage[].
    ENDIF.
  ENDIF.
ENDFORM.                                                                                          "retrieveMessageClass

*----------------------------------------------------------------------------------------------------------------------
*  retrieveFunctions...   Retrieve function modules from SAP DB.  May be called in one of two ways
*----------------------------------------------------------------------------------------------------------------------
FORM retrievefunctions USING sofname LIKE sofunctionname[]
                             sofgroup LIKE sofunctiongroup[]
                             ilocfunctionnames LIKE ifunctions[]
                             value(solocauthor) LIKE soauthor[]
                             value(gettextelements)
                             value(getscreens)
                             value(customeronly)
                             value(customernamerange)
                             value(solocpackage) LIKE sopack[].

  DATA: wafunctionname TYPE tfunction.
  DATA: nogroupsfound TYPE abap_bool VALUE true.
  DATA: previousfg TYPE v_fdir-area.

* select by function name and/or function group.
  SELECT a~funcname AS functionname
         a~area AS functiongroup
         INTO CORRESPONDING FIELDS OF TABLE ilocfunctionnames
         FROM v_fdir AS a
         INNER JOIN tlibv AS b
           ON a~area = b~area
         INNER JOIN tadir AS c
           ON a~area = c~obj_name
         WHERE a~funcname IN sofname[]
           AND a~area IN sofgroup[]
           AND a~generated = ''
           AND b~uname IN solocauthor[]
           AND pgmid = 'R3TR'
           AND object = 'FUGR'
           AND devclass IN solocpackage[]
           ORDER BY a~area.

  LOOP AT ilocfunctionnames INTO wafunctionname.
    PERFORM retrievefunctiondetail USING wafunctionname-functionname
                                         wafunctionname-progname
                                         wafunctionname-includenumber
                                         wafunctionname-functiontitle.

    PERFORM findmainfunctioninclude USING wafunctionname-progname
                                          wafunctionname-functiongroup
                                          wafunctionname-includenumber
                                          wafunctionname-functionmaininclude.

    PERFORM findfunctiontopinclude USING wafunctionname-progname
                                         wafunctionname-functiongroup
                                         wafunctionname-topincludename.

*   Find all user defined includes within the function group
    PERFORM scanforfunctionincludes USING wafunctionname-progname
                                          customeronly
                                          customernamerange
                                          wafunctionname-iincludes[].
*   Find main message class
    PERFORM findmainmessageclass USING wafunctionname-progname
                                       wafunctionname-messageclass.

*   Find any screens declared within the main include
    IF NOT getscreens IS INITIAL.
      IF previousfg IS INITIAL OR previousfg <> wafunctionname-functiongroup.
        PERFORM findfunctionscreenflow USING wafunctionname.

*       Search for any GUI texts
        PERFORM retrieveguititles USING wafunctionname-iguititle[]
                                        wafunctionname-progname.
      ENDIF.
    ENDIF.

    IF NOT gettextelements IS INITIAL.
*     Find the program texts from out of the database.
      PERFORM retrieveprogramtexts USING wafunctionname-iselectiontexts[]
                                         wafunctionname-itextelements[]
                                         wafunctionname-progname.
    ENDIF.

    previousfg = wafunctionname-functiongroup.
    MODIFY ilocfunctionnames FROM wafunctionname.
  ENDLOOP.
ENDFORM.                                                                                             "retrieveFunctions

*----------------------------------------------------------------------------------------------------------------------
*  retrieveFunctionDetail...   Retrieve function module details from SAP DB.
*----------------------------------------------------------------------------------------------------------------------
FORM retrievefunctiondetail USING value(functionname)
                                        progname
                                        includename
                                        titletext.

  SELECT SINGLE pname
                include
                FROM tfdir
                INTO (progname, includename)
                WHERE funcname = functionname.

  IF sy-subrc = 0.
    SELECT SINGLE stext
                  FROM tftit
                  INTO titletext
                  WHERE spras = pmlang
                    AND funcname = functionname.
  ENDIF.
ENDFORM.                                                                                        "retrieveFunctionDetail                                                                                  "findFunctionTopInclude

*----------------------------------------------------------------------------------------------------------------------
* scanForAdditionalFuncStuff... Search for additional things relating to functions
*----------------------------------------------------------------------------------------------------------------------
FORM scanforadditionalfuncstuff USING ilocfunctions LIKE ifunctions[]
                                      value(recursiveincludes)
                                      value(recursivefunctions)
                                      value(searchforincludes)
                                      value(searchforfunctions)
                                      value(searchfordictionary)
                                      value(searchformessages)
                                      value(searchfortransformations)
                                      value(customeronly)
                                      value(customernamerange).

  DATA: wafunction TYPE tfunction.
  DATA: wainclude TYPE tinclude.

  LOOP AT ilocfunctions INTO wafunction.
    IF NOT searchforincludes IS INITIAL.
*     Search in the main program
      PERFORM scanforincludeprograms USING wafunction-progname
                                           recursiveincludes
                                           customeronly
                                           customernamerange
                                           wafunction-iincludes[].

*     Search in the main include
      PERFORM scanforincludeprograms USING wafunction-functionmaininclude
                                           recursiveincludes
                                           customeronly
                                           customernamerange
                                           wafunction-iincludes[].

*     Search in the top include
      PERFORM scanforincludeprograms USING wafunction-topincludename
                                           recursiveincludes
                                           customeronly
                                           customernamerange
                                           wafunction-iincludes[].
    ENDIF.

    IF NOT searchforfunctions IS INITIAL.
      PERFORM scanforfunctions USING wafunction-functionmaininclude
                                     wafunction-programlinkname
                                     recursiveincludes
                                     recursivefunctions
                                     customeronly
                                     customernamerange
                                     ilocfunctions[].
    ENDIF.

    MODIFY ilocfunctions FROM wafunction.
  ENDLOOP.


  LOOP AT ilocfunctions INTO wafunction.
*   Now we have everthing perhaps we had better find all the dictionary structures
    IF NOT searchfordictionary IS INITIAL.
      PERFORM scanfortables USING wafunction-progname
                                  customeronly
                                  customernamerange
                                  wafunction-idictstruct[].

      PERFORM scanforlikeortype USING wafunction-progname
                                      customeronly
                                      customernamerange
                                      wafunction-idictstruct[]
                                      wafunction-itabletypes[].

      PERFORM scanfortables USING wafunction-functionmaininclude
                                  customeronly
                                  customernamerange
                                  wafunction-idictstruct[].

      PERFORM scanforlikeortype USING wafunction-functionmaininclude
                                      customeronly
                                      customernamerange
                                      wafunction-idictstruct[]
                                      wafunction-itabletypes[].

      LOOP AT wafunction-iincludes INTO wainclude.
        PERFORM scanfortables USING wainclude-includename
                                    customeronly
                                    customernamerange
                                    wafunction-idictstruct[].

        PERFORM scanforlikeortype USING wainclude-includename
                                        customeronly
                                        customernamerange
                                        wafunction-idictstruct[]
                                        wafunction-itabletypes[].
      ENDLOOP.

      MODIFY ilocfunctions FROM wafunction.
    ENDIF.

*   Now search for all messages
    IF NOT searchformessages IS INITIAL.
      PERFORM scanformessages USING wafunction-progname
                                    wafunction-messageclass
                                    wafunction-imessages[].
      MODIFY ilocfunctions FROM wafunction.
    ENDIF.

*   Search for TRansformations.
    IF NOT searchfortransformations IS INITIAL.
      PERFORM scanfortransformations USING wafunction-progname
                                           customeronly
                                           customernamerange
                                           wafunction-itransformations[].
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                    "scanForAdditionalFuncStuff

*----------------------------------------------------------------------------------------------------------------------
* scanForClasses... Search each class or method for other classes
*----------------------------------------------------------------------------------------------------------------------
FORM scanforclasses USING value(classname)
                          value(classlinkname)
                          value(customeronly)
                          value(customernamerange)
                                ilocclasses LIKE iclasses[]
                          value(solocpackage) LIKE sopack[].

  DATA ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: head TYPE string.
  DATA: tail TYPE string.
  DATA: linelength TYPE i VALUE 0.
  DATA: waline TYPE string.
  DATA: waclass TYPE tclass.
  DATA: wasearchclass TYPE tclass.
  DATA: castclassname TYPE program.
  DATA: exceptioncustomernamerange TYPE string.

* Build the name of the possible cusotmer exception classes
  CONCATENATE customernamerange 'CX_' INTO  exceptioncustomernamerange.

* Read the program code from the textpool.
  castclassname = classname.
  READ REPORT castclassname INTO ilines.

  LOOP AT ilines INTO waline.
*   Find custom tables.
    linelength = strlen( waline ).
    IF linelength > 0.
      IF waline(1) = asterix.
        CONTINUE.
      ENDIF.

      TRANSLATE waline TO UPPER CASE.

      FIND typerefto IN waline IGNORING CASE.
      IF sy-subrc = 0.
*       Have found a reference to another class
        SPLIT waline AT type INTO head tail.
        SHIFT tail LEFT DELETING LEADING space.
        SPLIT tail AT 'REF' INTO head tail.
        SHIFT tail LEFT DELETING LEADING space.
        SPLIT tail AT 'TO' INTO head tail.
        SHIFT tail LEFT DELETING LEADING space.
        IF tail CS period.
          SPLIT tail AT period INTO head tail.
        ELSE.
          IF tail CS comma.
            SPLIT tail AT comma INTO head tail.
          ENDIF.
        ENDIF.
      ELSE.
*       Try and find classes which are only referenced through static mehods
        FIND '=>' IN waline MATCH OFFSET sy-fdpos.
        IF sy-subrc = 0.
          head = waline+0(sy-fdpos).
          SHIFT head LEFT DELETING LEADING space.
          CONDENSE head.
          FIND 'call method' IN head IGNORING CASE.
          IF sy-subrc = 0.
            SHIFT head LEFT DELETING LEADING space.
            SPLIT head AT space INTO head tail.
            SPLIT tail AT space INTO head tail.
*           Should have the class name here
            head = tail.
          ELSE.
*           Still have a class name even though it does not have the words call method in front
            IF waline CS '='.
              SPLIT waline AT '=' INTO tail head.
              SHIFT head LEFT DELETING LEADING space.
              SPLIT head AT '=' INTO head tail.
            ENDIF.
            sy-subrc = 0.
          ENDIF.
        ENDIF.
      ENDIF.

      IF sy-subrc = 0.
        TRY.
            IF head+0(1) = 'Y' OR head+0(1) = 'Z' OR head CS customernamerange.
*           We have found a class best append it to our class table if we do not already have it.
              READ TABLE ilocclasses INTO wasearchclass WITH KEY clsname = head.
              IF sy-subrc <> 0.
                IF head+0(3) = 'CX_'
                   OR head+0(4) = 'ZCX_'
                   OR head+0(4) = 'YCX_'
                   OR head CS exceptioncustomernamerange.

                  waclass-exceptionclass = true.
                ENDIF.

                waclass-clsname = head.

*             Check the package
                IF NOT solocpackage[] IS INITIAL.
                  SELECT SINGLE obj_name
                         FROM tadir
                         INTO waclass-clsname
                         WHERE pgmid = 'R3TR'
                           AND object = 'CLAS'
                           AND obj_name = waclass-clsname
                           AND devclass IN solocpackage[].
                  IF sy-subrc = 0.
                    APPEND waclass TO ilocclasses.
                  ENDIF.
                ELSE.
                  APPEND waclass TO ilocclasses.
                ENDIF.
              ENDIF.
            ENDIF.
          CATCH cx_sy_range_out_of_bounds.
        ENDTRY.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                                "scanForClasses

*----------------------------------------------------------------------------------------------------------------------
* scanForIncludePrograms... Search each program for include programs
*----------------------------------------------------------------------------------------------------------------------
FORM scanforincludeprograms USING value(programname)
                                  value(recursiveincludes)
                                  value(customeronly)
                                  value(customernamerange)
                                        ilocincludes LIKE dumiincludes[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: watokens TYPE stokes.
  DATA: wainclude TYPE tinclude.
  DATA: waincludeexists TYPE tinclude.
  DATA: maxlines TYPE i.
  DATA: nextline TYPE i.
  DATA: castprogramname TYPE program.

* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO iincludelines.

  APPEND include TO ikeywords.
  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements KEYWORDS FROM ikeywords.

  CLEAR iincludelines[].

  maxlines = lines( itokens ).
  LOOP AT itokens WHERE str = include AND type = 'I'.
    nextline = sy-tabix + 1.
    IF nextline <= maxlines.
      READ TABLE itokens INDEX nextline INTO watokens.

*      Are we only to find customer includes?
      IF NOT customeronly IS INITIAL.
        TRY.
            IF watokens-str+0(1) = 'Y' OR watokens-str+0(1) = 'Z' OR watokens-str CS customernamerange
               OR watokens-str+0(2) = 'MZ' OR watokens-str+0(2) = 'MY'.

            ELSE.
              CONTINUE.
            ENDIF.
          CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
        ENDTRY.
      ENDIF.

      wainclude-includename = watokens-str.

*      Best find the program title text as well.
      PERFORM findprogramorincludetitle USING wainclude-includename
                                              wainclude-includetitle.

*      Don't append the include if we already have it listed
      READ TABLE ilocincludes INTO waincludeexists WITH KEY includename = wainclude-includename.
      IF sy-subrc <> 0.
        APPEND wainclude TO ilocincludes.

        IF NOT recursiveincludes IS INITIAL.
*          Do a recursive search for other includes
          PERFORM scanforincludeprograms USING wainclude-includename
                                               recursiveincludes
                                               customeronly
                                               customernamerange
                                               ilocincludes[].
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                        "scanForIncludePrograms

*----------------------------------------------------------------------------------------------------------------------
* scanForIncludePrograms... Search each program for include programs
*----------------------------------------------------------------------------------------------------------------------
FORM scanfortransformations USING value(programname)
                                  value(customeronly)
                                  value(customernamerange)
                                        iloctransformation LIKE itransformations[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: watokens TYPE stokes.
  DATA: watransformation TYPE ttransformation.
  DATA: watransformationexists TYPE ttransformation.
  DATA: maxlines TYPE i.
  DATA: nextline TYPE i.
  DATA: castprogramname TYPE program.


* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO iincludelines.

  APPEND 'CALL' TO ikeywords.
  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements KEYWORDS FROM ikeywords.

  CLEAR iincludelines[].

  maxlines = lines( itokens ).
  LOOP AT itokens WHERE str = transformation AND type = 'I'.
    nextline = sy-tabix + 1.
    IF nextline <= maxlines.
      READ TABLE itokens INDEX nextline INTO watokens.

*      Are we only to find customer transformations?
      IF NOT customeronly IS INITIAL.
        TRY.
            IF watokens-str+0(1) = 'Y' OR watokens-str+0(1) = 'Z' OR watokens-str CS customernamerange.
            ELSE.
              CONTINUE.
            ENDIF.
          CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
        ENDTRY.
      ENDIF.

      watransformation-xsltname = watokens-str.

*      Don't append the include if we already have it listed
      READ TABLE iloctransformation INTO watransformationexists WITH KEY xsltname = watransformation-xsltname.
      IF sy-subrc <> 0.
        APPEND watransformation TO iloctransformation.

        PERFORM scanfortransincludes USING watransformation-xsltname
                                           customeronly
                                           customernamerange
                                           iloctransformation[].

      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                        "scanForIncludePrograms

*----------------------------------------------------------------------------------------------------------------------
* scanforTransIncludes...
*----------------------------------------------------------------------------------------------------------------------
FORM scanfortransincludes USING value(xsltname)
                                value(customeronly)
                                value(customernamerange)
                                      iloctransformations LIKE itransformations[].

  DATA: ixsltsource TYPE o2pageline_table.
  DATA: waxsltattributes TYPE o2xsltattr.
  DATA: waxsltsource LIKE LINE OF ixsltsource.
  DATA: dummy TYPE string.
  DATA: watransformationexists TYPE ttransformation.
  DATA: watransformation TYPE ttransformation.

  cl_o2_api_xsltdesc=>load( EXPORTING p_xslt_desc = xsltname
                           IMPORTING p_source = ixsltsource
                                     p_attributes = waxsltattributes
                           EXCEPTIONS not_existing = 1
                                      permission_failure = 2
                                      error_occured = 3
                                      version_not_found = 4 ).

  LOOP AT ixsltsource INTO waxsltsource.
    IF waxsltsource-line CS '<xsl:include'.
      SPLIT waxsltsource-line AT '"' INTO dummy waxsltsource-line.
      SPLIT waxsltsource-line AT '"' INTO waxsltsource dummy.

*      Are we only to find customer transformations?
      IF NOT customeronly IS INITIAL.
        TRY.
            IF waxsltsource-line+0(1) = 'Y' OR waxsltsource-line+0(1) = 'Z' OR waxsltsource-line CS customernamerange.
            ELSE.
              CONTINUE.
            ENDIF.
          CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
        ENDTRY.
      ENDIF.

*      Don't append the include if we already have it listed
      READ TABLE iloctransformations INTO watransformationexists WITH KEY xsltname = waxsltsource-line.
      IF sy-subrc <> 0.
        watransformation-xsltname = waxsltsource-line.
        APPEND watransformation TO iloctransformations.

*        Ok we have an include.  Are there any sub includes
        PERFORM scanfortransincludes USING watransformation-xsltname
                                           customeronly
                                           customernamerange
                                           iloctransformations[].
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "scanforTransIncludes


*----------------------------------------------------------------------------------------------------------------------
* scanForFunctions... Search each program for function modules
*----------------------------------------------------------------------------------------------------------------------
FORM scanforfunctions USING value(programname)
                            value(programlinkname)
                            value(recursiveincludes)
                            value(recursivefunctions)
                            value(customeronly)
                            value(customernamerange)
                                  ilocfunctions LIKE ifunctions[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: watokens TYPE stokes.
  DATA: wafunction TYPE tfunction.
  DATA: wafunctioncomparison TYPE tfunction.
  DATA: maxlines TYPE i.
  DATA: nextline TYPE i.
  DATA: castprogramname TYPE program.
  DATA: skipthisloop TYPE abap_bool.

* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO iincludelines.
  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements.
  CLEAR iincludelines[].

  maxlines = lines( itokens ).
  LOOP AT itokens WHERE str = function AND type = 'I'.

    nextline = sy-tabix + 1.
    IF nextline <= maxlines.
      READ TABLE itokens INDEX nextline INTO watokens.

*      Are we only to find customer functions
      skipthisloop = false.
      IF NOT customeronly IS INITIAL.
        TRY.
            IF watokens-str+1(1) = 'Y' OR watokens-str+1(1) = 'Z' OR watokens-str CS customernamerange.
            ELSE.
              skipthisloop = true.
            ENDIF.
          CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
          CLEANUP.
            skipthisloop = true.
        ENDTRY.
      ENDIF.

      IF skipthisloop = false.
        wafunction-functionname = watokens-str.
        REPLACE ALL OCCURRENCES OF '''' IN wafunction-functionname WITH ' '.
        CONDENSE wafunction-functionname.

*        Don't add a function if we alread have it listed.
        READ TABLE ilocfunctions WITH KEY functionname = wafunction-functionname INTO wafunctioncomparison.
        IF sy-subrc <> 0.
*          Add in the link name if the function is linked to a program
          wafunction-programlinkname = programlinkname.

*          Don't download functions which are called through an RFC destination
          nextline = sy-tabix + 2.
          READ TABLE itokens INDEX nextline INTO watokens.
          IF watokens-str <> destination.

*            Find the function group
            SELECT SINGLE area FROM v_fdir INTO wafunction-functiongroup WHERE funcname = wafunction-functionname.

            IF sy-subrc = 0.
*              Best find the function number as well.
              PERFORM retrievefunctiondetail USING wafunction-functionname
                                                   wafunction-progname
                                                   wafunction-includenumber
                                                   wafunction-functiontitle.

              PERFORM findmainfunctioninclude USING wafunction-progname
                                                    wafunction-functiongroup
                                                    wafunction-includenumber
                                                    wafunction-functionmaininclude.

              PERFORM findfunctiontopinclude USING wafunction-progname
                                                   wafunction-functiongroup
                                                   wafunction-topincludename.

*              Find main message class
              PERFORM findmainmessageclass USING wafunction-progname
                                                 wafunction-messageclass.

              APPEND wafunction TO ilocfunctions.

*              Now lets search a little bit deeper and do a recursive search for other includes
              IF NOT recursiveincludes IS INITIAL.
                PERFORM scanforincludeprograms USING wafunction-functionmaininclude
                                                     recursiveincludes
                                                     customeronly
                                                     customernamerange
                                                     wafunction-iincludes[].
              ENDIF.

*              Now lets search a little bit deeper and do a recursive search for other functions
              IF NOT recursivefunctions IS INITIAL.
                PERFORM scanforfunctions USING wafunction-functionmaininclude
                                               space
                                               recursiveincludes
                                               recursivefunctions
                                               customeronly
                                               customernamerange
                                               ilocfunctions[].
              ENDIF.
              CLEAR wafunction.
            ENDIF.
          ENDIF.
        ENDIF.

        CLEAR wafunction.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                              "scanForFunctions

*----------------------------------------------------------------------------------------------------------------------
*  scanForFunctionIncludes... Find all user defined includes within the function group
*----------------------------------------------------------------------------------------------------------------------
FORM scanforfunctionincludes USING poolname
                                   value(customeronly)
                                   value(customernamerange)
                                   ilocincludes LIKE dumiincludes[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: watokens TYPE stokes.
  DATA: wainclude TYPE tinclude.
  DATA: waincludeexists TYPE tinclude.
  DATA: maxlines TYPE i.
  DATA: nextline TYPE i.
  DATA: castprogramname TYPE program.

* Read the program code from the textpool.
  castprogramname = poolname.
  READ REPORT castprogramname INTO iincludelines.

  APPEND include TO ikeywords.
  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements KEYWORDS FROM ikeywords.

  CLEAR iincludelines[].

  maxlines = lines( itokens ).
  LOOP AT itokens WHERE str = include AND type = 'I'.
    nextline = sy-tabix + 1.
    IF nextline <= maxlines.
      READ TABLE itokens INDEX nextline INTO watokens.

      IF watokens-str CP '*F++'.
*        Are we only to find customer includes?
        IF NOT customeronly IS INITIAL.
          TRY.
              IF watokens-str+0(2) = 'LY' OR watokens-str+0(2) = 'LZ' OR watokens-str CS customernamerange.
              ELSE.
                CONTINUE.
              ENDIF.
            CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
          ENDTRY.
        ENDIF.

        wainclude-includename = watokens-str.

*        Best find the program title text as well.
        PERFORM findprogramorincludetitle USING wainclude-includename
                                                wainclude-includetitle.

*        Don't append the include if we already have it listed
        READ TABLE ilocincludes INTO waincludeexists WITH KEY includename = wainclude-includename.
        IF sy-subrc <> 0.
          APPEND wainclude TO ilocincludes.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                       "scanForFunctionIncludes

*----------------------------------------------------------------------------------------------------------------------
*  findProgramOrIncludeTitle...   Finds the title text of a program.
*----------------------------------------------------------------------------------------------------------------------
FORM findprogramorincludetitle USING value(programname)
                                           titletext.

  SELECT SINGLE text
                FROM trdirt
                INTO titletext
                WHERE name = programname
                  AND sprsl = pmlang.
ENDFORM.                                                                                     "findProgramOrIncludeTitle

*----------------------------------------------------------------------------------------------------------------------
* retrievePrograms...    find programs and sub objects from SAP DB
*----------------------------------------------------------------------------------------------------------------------
FORM retrieveprograms USING ilocprogram LIKE iprograms[]
                            ilocfunctions LIKE ifunctions[]
                            rangeprogram LIKE soprogramname[]
                            rangeauthor LIKE soauthor[]
                            value(custnamerange)
                            value(alsomodifiedbyauthor)
                            value(customerprogsonly)
                            value(getmessages)
                            value(gettextelements)
                            value(getcustdictstructures)
                            value(getfunctions)
                            value(getincludes)
                            value(getscreens)
                            value(gettransformations)
                            value(recursivefuncsearch)
                            value(recursiveincludesearch)
                            value(solocpackage) LIKE sopack[].

  DATA: warangeprogram LIKE LINE OF rangeprogram.

  IF rangeprogram[] IS INITIAL.
*   We are finding all programs by an author
    PERFORM findallprogramsforauthor USING ilocprogram[]
                                           rangeprogram[]
                                           rangeauthor[]
                                           custnamerange
                                           alsomodifiedbyauthor
                                           customerprogsonly
                                           solocpackage[].
  ELSE.
    READ TABLE rangeprogram INDEX 1 INTO warangeprogram.
    IF warangeprogram-low CS asterix.
      PERFORM findprogramsbywildcard USING ilocprogram[]
                                           rangeprogram[]
                                           rangeauthor[]
                                           custnamerange
                                           customerprogsonly
                                           solocpackage[].
    ELSE.
      PERFORM checkprogramdoesexist USING ilocprogram[]
                                          rangeprogram[].
    ENDIF.
  ENDIF.

* Find extra items
  PERFORM scanforadditionalprogstuff USING ilocprogram[]
                                           ilocfunctions[]
                                           gettextelements
                                           getmessages
                                           getscreens
                                           getcustdictstructures
                                           getfunctions
                                           getincludes
                                           gettransformations
                                           customerprogsonly
                                           custnamerange
                                           recursiveincludesearch
                                           recursivefuncsearch.
ENDFORM.                                                                               "retrievePrograms

*-------------------------------------------------------------------------------------------------------
*  scanForAdditionalProgStuff...
*-------------------------------------------------------------------------------------------------------
FORM scanforadditionalprogstuff USING ilocprogram LIKE iprograms[]
                                      ilocfunctions LIKE ifunctions[]
                                      value(gettextelements)
                                      value(getmessages)
                                      value(getscreens)
                                      value(getcustdictstructures)
                                      value(getfunctions)
                                      value(getincludes)
                                      value(gettransformations)
                                      value(customeronly)
                                      value(customernamerange)
                                      value(recursiveincludesearch)
                                      value(recursivefuncsearch).

  DATA: waprogram TYPE tprogram.
  DATA: wainclude TYPE tinclude.
  DATA: mytabix TYPE sytabix.

* Best to find all the includes used in a program first
  IF NOT getincludes IS INITIAL.
    LOOP AT ilocprogram INTO waprogram.
      mytabix = sy-tabix.
      PERFORM scanforincludeprograms USING waprogram-progname
                                           recursiveincludesearch
                                           customeronly
                                           customernamerange
                                           waprogram-iincludes[].

      MODIFY ilocprogram FROM waprogram INDEX mytabix.
    ENDLOOP.
  ENDIF.

* Once we have a list of all the includes we need to loop round them an select all the other objects
  LOOP AT ilocprogram INTO waprogram.
    mytabix = sy-tabix.
    PERFORM findprogramdetails USING waprogram-progname
                                     waprogram-subc
                                     waprogram-programtitle
                                     waprogram
                                     gettextelements
                                     getmessages
                                     getscreens
                                     gettransformations
                                     getcustdictstructures
                                     customeronly
                                     customernamerange.

*   Find any screens
    IF NOT getscreens IS INITIAL.
      PERFORM findprogramscreenflow USING waprogram.
    ENDIF.

    LOOP AT waprogram-iincludes INTO wainclude.
      PERFORM findprogramdetails USING wainclude-includename
                                       'I'
                                       wainclude-includetitle
                                       waprogram
                                       gettextelements
                                       getmessages
                                       getscreens
                                       gettransformations
                                       getcustdictstructures
                                       customeronly
                                       customernamerange.
    ENDLOOP.

    MODIFY ilocprogram FROM waprogram INDEX mytabix.
  ENDLOOP.

* Now we have all the program includes and details we need to find extra functions
  IF NOT getfunctions IS INITIAL.
    LOOP AT ilocprogram INTO waprogram.
*     Find any functions defined in the code
      PERFORM scanforfunctions USING waprogram-progname
                                     waprogram-progname
                                     space
                                     space
                                     customeronly
                                     customernamerange
                                     ilocfunctions[].
    ENDLOOP.

*   We have a list of all the functions so lets go and find details and other function calls
    PERFORM scanforadditionalfuncstuff USING ilocfunctions[]
                                             recursiveincludesearch
                                             recursivefuncsearch
                                             getincludes
                                             getfunctions
                                             getcustdictstructures
                                             getmessages
                                             gettransformations
                                             customeronly
                                             customernamerange.
  ENDIF.
ENDFORM.                                                                     "scanForAdditionalProgStuff

*-------------------------------------------------------------------------------------------------------
*  findProgramDetails...
*-------------------------------------------------------------------------------------------------------
FORM findprogramdetails USING value(programname)
                              value(programtype)
                                    programtitle
                                    waprogram TYPE tprogram
                              value(gettextelements)
                              value(getmessages)
                              value(getscreens)
                              value(gettransformations)
                              value(getcustdictstructures)
                              value(customeronly)
                              value(customernamerange).

  PERFORM findprogramorincludetitle USING programname
                                          programtitle.

  IF NOT gettextelements IS INITIAL.
*   Find the program texts from out of the database.
    PERFORM retrieveprogramtexts USING waprogram-iselectiontexts[]
                                       waprogram-itextelements[]
                                       programname.
  ENDIF.

* Search for any GUI texts
  IF NOT getscreens IS INITIAL AND ( programtype = 'M' OR programtype = '1' ).
    PERFORM retrieveguititles USING waprogram-iguititle[]
                                    programname.
  ENDIF.

* Find individual messages
  IF NOT getmessages IS INITIAL.
    IF programtype = 'M' OR programtype = '1'.
      PERFORM findmainmessageclass USING programname
                                         waprogram-messageclass.
    ENDIF.

    PERFORM scanformessages USING programname
                                  waprogram-messageclass
                                  waprogram-imessages[].
  ENDIF.

* Find any XSLT Transformations
  IF NOT gettransformations IS INITIAL.
    PERFORM scanfortransformations USING programname
                                         customeronly
                                         customernamerange
                                         waprogram-itransformations[].
  ENDIF.

  IF NOT getcustdictstructures IS INITIAL.
    PERFORM scanfortables USING programname
                                customeronly
                                customernamerange
                                waprogram-idictstruct[].

    PERFORM scanforlikeortype USING programname
                                    customeronly
                                    customernamerange
                                    waprogram-idictstruct[]
                                    waprogram-itabletypes[].
  ENDIF.
ENDFORM.                                                                             "findProgramDetails

*-------------------------------------------------------------------------------------------------------
*  findAllProgramsForAuthor...
*-------------------------------------------------------------------------------------------------------
FORM findallprogramsforauthor USING ilocprogram LIKE iprograms[]
                                    rangeprogram LIKE soprogramname[]
                                    rangeauthor LIKE soauthor[]
                                    value(custnamerange)
                                    value(alsomodifiedbyauthor)
                                    value(customerprogsonly)
                                    value(solocpackage) LIKE sopack[].

  DATA: altcustomernamerange TYPE string.
  FIELD-SYMBOLS: <waprogram> TYPE tprogram.
  DATA: genflag TYPE genflag.

* build up the customer name range used for select statements
  CONCATENATE custnamerange '%' INTO altcustomernamerange.

* select by name and author
  IF NOT alsomodifiedbyauthor IS INITIAL.
*   Programs modified by author
*   Program to search for is an executable program
    IF customerprogsonly IS INITIAL.
*     Select all programs
      SELECT a~progname
             a~subc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             FROM reposrc AS a
             INNER JOIN tadir AS b
               ON a~progname = b~obj_name
             WHERE a~progname IN rangeprogram
               AND a~cnam IN rangeauthor
               AND ( a~subc = '1' OR a~subc = 'M' OR a~subc = 'S' )
               AND b~pgmid = 'R3TR'
               AND b~object = 'PROG'
               AND b~devclass IN solocpackage.

    ELSE.
*     Select only customer specific programs
      SELECT progname
             subc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             FROM reposrc AS a
             INNER JOIN tadir AS b
               ON a~progname = b~obj_name
             WHERE a~progname  IN rangeprogram
               AND ( a~progname LIKE altcustomernamerange
                     OR a~progname LIKE 'Z%'
                     OR a~progname LIKE 'Y%'
                     OR a~progname LIKE 'SAPMZ%'
                     OR a~progname LIKE 'SAPMY%')
               AND a~cnam IN rangeauthor
               AND ( a~subc = '1' OR a~subc = 'M' OR a~subc = 'S' )
               AND b~pgmid = 'R3TR'
               AND b~object = 'PROG'
               AND b~devclass IN solocpackage.
    ENDIF.
  ELSE.

*   Programs created by author
    IF customerprogsonly IS INITIAL.
*     Select all programs
      SELECT progname
             subc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             FROM reposrc AS a
             INNER JOIN tadir AS b
               ON a~progname = b~obj_name
             WHERE a~progname IN rangeprogram
               AND ( a~subc = '1' OR a~subc = 'M' OR a~subc = 'S' )
               AND ( a~cnam IN rangeauthor OR a~unam IN rangeauthor )
               AND b~pgmid = 'R3TR'
               AND b~object = 'PROG'
               AND b~devclass IN solocpackage.
    ELSE.
*     Select only customer specific programs
      SELECT a~progname
             a~subc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             FROM reposrc AS a
             INNER JOIN tadir AS b
               ON a~progname = b~obj_name
             WHERE a~progname IN rangeprogram
               AND ( a~progname LIKE altcustomernamerange
                     OR a~progname LIKE 'Z%'
                     OR a~progname LIKE 'Y%'
                     OR a~progname LIKE 'SAPMZ%'
                     OR a~progname LIKE 'SAPMY%')
               AND ( a~subc = '1' OR a~subc = 'M' OR a~subc = 'S' )
               AND ( a~cnam IN rangeauthor OR a~unam IN rangeauthor )
               AND b~pgmid = 'R3TR'
               AND b~object = 'PROG'
               AND b~devclass IN solocpackage.
    ENDIF.
  ENDIF.
ENDFORM.                                                                       "findAllProgramsForAuthor

*-------------------------------------------------------------------------------------------------------
*  findAllXSLTForAuthor...
*-------------------------------------------------------------------------------------------------------
FORM findallxsltforauthor USING iloctransformations  LIKE itransformations[]
                                rangexslt LIKE soxsltname[]
                                rangeauthor LIKE soauthor[]
                                value(custnamerange)
                                value(alsomodifiedbyauthor)
                                value(customerprogsonly)
                                value(solocpackage) LIKE sopack[].

  DATA: altcustomernamerange TYPE string.
  DATA: watransformation LIKE LINE OF itransformations.
  FIELD-SYMBOLS: <waxslt> TYPE ttransformation.
  DATA: genflag TYPE genflag.

* build up the customer name range used for select statements
  CONCATENATE custnamerange '%' INTO altcustomernamerange.

* select by name and author
  IF NOT alsomodifiedbyauthor IS INITIAL.
*   Programs modified by author
*   Program to search for is an executable program
    IF customerprogsonly IS INITIAL.
*     Select all XSLT programs
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    author    IN rangeauthor
             AND    obj_name  IN rangexslt
             AND    devclass  IN solocpackage.

        APPEND watransformation TO iloctransformations.
      ENDSELECT.

    ELSE.
*     Select only customer specific programs
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    author    IN rangeauthor
             AND    obj_name  IN rangexslt
             AND    devclass  IN solocpackage
             AND ( obj_name LIKE altcustomernamerange
                   OR obj_name LIKE 'Z%'
                   OR obj_name LIKE 'Y%').

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ENDIF.
  ELSE.
*   Programs created by author
    IF customerprogsonly IS INITIAL.
*     Select all programs
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    author    IN rangeauthor
             AND    obj_name  IN rangexslt
             AND    devclass  IN solocpackage.

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ELSE.
*     Select only customer specific programs
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    author    IN rangeauthor
             AND    obj_name  IN rangexslt
             AND    devclass  IN solocpackage
             AND ( obj_name LIKE altcustomernamerange
                   OR obj_name LIKE 'Z%'
                   OR obj_name LIKE 'Y%').

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ENDIF.
  ENDIF.
ENDFORM.                                                                       "findAllXSLTForAuthor

*-------------------------------------------------------------------------------------------------------
*  findXsltByWildcard...
*-------------------------------------------------------------------------------------------------------
FORM findxsltbywildcard USING iloctransformations LIKE itransformations[]
                                  value(rangexslt) LIKE soxsltname[]
                                  value(rangeauthor) LIKE soauthor[]
                                  value(custnamerange)
                                  value(customerprogsonly)
                                  value(solocpackage) LIKE sopack[].

  DATA: altcustomernamerange TYPE string.
  DATA: watransformation LIKE LINE OF iloctransformations.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.
  DATA: genflag TYPE genflag.

  IF customerprogsonly IS INITIAL.
*   build up the customer name range used for select statements
    IF custnamerange <> '^'.
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    obj_name  IN rangexslt
             AND    obj_name  LIKE altcustomernamerange
             AND    author    IN rangeauthor.

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ELSE.
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    obj_name  IN rangexslt
             AND    author    IN rangeauthor.

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ENDIF.
  ELSE.
*   Only customer xslt
    IF custnamerange <> '^'.
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    obj_name  IN rangexslt
             AND    obj_name  LIKE altcustomernamerange
             AND    ( obj_name LIKE 'Z%' OR
                      obj_name LIKE 'Y%' ).

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ELSE.
      SELECT obj_name
             INTO   watransformation-xsltname
             FROM   tadir
             WHERE  pgmid     = 'R3TR'
             AND    object    = 'XSLT'
             AND    obj_name  IN rangexslt
             AND    ( obj_name LIKE 'Z%' OR
                      obj_name LIKE 'Y%' ).

        APPEND watransformation TO iloctransformations.
      ENDSELECT.
    ENDIF.
  ENDIF.
ENDFORM.                                                                         "findxsltByWildcard

*-------------------------------------------------------------------------------------------------------
*  checkXsltDoesExist...
*-------------------------------------------------------------------------------------------------------
FORM checkxsltdoesexist USING iloctransformations LIKE itransformations[]
                              rangexslt LIKE soxsltname[].

  DATA: watransformation TYPE ttransformation.

*-- Make sure XSLT exists
  SELECT SINGLE obj_name
         INTO   watransformation-xsltname
         FROM   tadir
         WHERE  pgmid     = 'R3TR'
         AND    object    = 'XSLT'
         AND    obj_name  IN rangexslt.

  IF sy-subrc = 0.
    APPEND watransformation TO iloctransformations.
  ENDIF.
ENDFORM.                                                                          "checkxsltDoesExist

*-------------------------------------------------------------------------------------------------------
*  checkProgramDoesExist...
*-------------------------------------------------------------------------------------------------------
FORM checkprogramdoesexist USING ilocprogram LIKE iprograms[]
                                 rangeprogram LIKE soprogramname[].

*  Check to see if the program is an executable program
  SELECT progname
         subc
         INTO CORRESPONDING FIELDS OF TABLE ilocprogram
         FROM reposrc
         WHERE progname IN rangeprogram
           AND ( subc = '1' OR
                 subc = 'I' OR
                 subc = 'M' OR
                 subc = 'S' ).
ENDFORM.                                                                          "checkProgramDoesExist

*-------------------------------------------------------------------------------------------------------
*  findProgramsByWildcard.. Search in the system for programs
*-------------------------------------------------------------------------------------------------------
FORM checkandaddtabletype USING wadictionary-tablename
                                iloctabletypes LIKE itabletypes[].

  SELECT *
         INTO CORRESPONDING FIELDS OF TABLE iloctabletypes
         FROM dd40l AS a
         INNER JOIN dd40t AS t
            ON a~typename = t~typename
         WHERE a~typename = wadictionary-tablename
           AND t~ddlanguage EQ sy-langu
           AND a~as4local = 'A'.
ENDFORM.                    "checkAndAddTableType

*-------------------------------------------------------------------------------------------------------
*  findProgramsByWildcard.. Search in the system for programs
*-------------------------------------------------------------------------------------------------------
FORM findprogramsbywildcard USING ilocprogram LIKE iprograms[]
                                  value(rangeprogram) LIKE soprogramname[]
                                  value(rangeauthor) LIKE soauthor[]
                                  value(custnamerange)
                                  value(customerprogsonly)
                                  value(solocpackage) LIKE sopack[].

  DATA: altcustomernamerange TYPE string.
  FIELD-SYMBOLS: <waprogram> TYPE tprogram.
  DATA: genflag TYPE genflag.

  IF customerprogsonly IS INITIAL.
*   build up the customer name range used for select statements
    IF custnamerange <> '^'.
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT progname
             subc
             FROM reposrc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             WHERE progname  IN rangeprogram
               AND progname LIKE altcustomernamerange
               AND ( subc = '1' OR subc = 'M' OR subc = 'S' )
               AND ( cnam IN rangeauthor OR unam IN rangeauthor ).
    ELSE.
      SELECT progname
             subc
             FROM reposrc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             WHERE progname  IN rangeprogram
               AND ( subc = '1' OR subc = 'M' OR subc = 'S' )
               AND ( cnam IN rangeauthor OR unam IN rangeauthor ).
    ENDIF.
  ELSE.
*   Only customer programs
    IF custnamerange <> '^'.
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT progname
             subc
             FROM reposrc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             WHERE progname  IN rangeprogram
               AND ( progname LIKE altcustomernamerange
                     OR progname LIKE 'Z%'
                     OR progname LIKE 'Y%'
                     OR progname LIKE 'SAPMZ%'
                     OR progname LIKE 'SAPMY%')
               AND ( subc = '1' OR subc = 'M' OR subc = 'S' )
               AND ( cnam IN rangeauthor OR unam IN rangeauthor ).
    ELSE.
      SELECT progname
             subc
             FROM reposrc
             APPENDING CORRESPONDING FIELDS OF TABLE ilocprogram
             WHERE progname  IN rangeprogram
             AND ( progname LIKE 'Z%'
                   OR progname LIKE 'Y%'
                   OR progname LIKE 'SAPMZ%'
                   OR progname LIKE 'SAPMY%')
             AND ( subc = '1' OR subc = 'M' OR subc = 'S' )
             AND ( cnam IN rangeauthor OR unam IN rangeauthor ).
    ENDIF.
  ENDIF.
ENDFORM.                                                                         "findProgramsByWildcard

*-------------------------------------------------------------------------------------------------------
*  retrieveProgramTexts... Find the text elements and selection texts for a program
*-------------------------------------------------------------------------------------------------------
FORM retrieveprogramtexts USING ilocselectiontexts LIKE dumitexttab[]
                                iloctextelements LIKE dumitexttab[]
                                value(programname).

  DATA: itexttable TYPE STANDARD TABLE OF ttexttable WITH HEADER LINE.
  DATA: watexts TYPE ttexttable.
  DATA: castprogramname(50).

  MOVE programname TO castprogramname.

  READ TEXTPOOL castprogramname INTO itexttable LANGUAGE pmlang.
  DELETE itexttable WHERE key = 'R'.

* Selection texts.
  LOOP AT itexttable WHERE id = 'S'.
    MOVE itexttable-key TO watexts-key.
    MOVE itexttable-entry TO watexts-entry.
    APPEND watexts TO ilocselectiontexts.
    CLEAR watexts.
  ENDLOOP.

* Text elements.
  DELETE itexttable WHERE key = 'S'.
  LOOP AT itexttable WHERE id = 'I'.
    MOVE itexttable-key TO watexts-key.
    MOVE itexttable-entry TO watexts-entry.
    APPEND watexts TO iloctextelements.
  ENDLOOP.
ENDFORM.                                                                           "retrieveProgramTexts

*-------------------------------------------------------------------------------------------------------
*  retrieveGUITitles...  Search for any GUI texts
*-------------------------------------------------------------------------------------------------------
FORM retrieveguititles USING ilocguititle LIKE dumiguititle[]
                             value(programname).

  SELECT obj_code
         text
         FROM d347t
         APPENDING CORRESPONDING FIELDS OF TABLE ilocguititle
         WHERE progname = programname.
ENDFORM.                                                                              "retrieveGUITitles

*-------------------------------------------------------------------------------------------------------
*   findMainMessageClass... find the message class stated at the top of  program.
*-------------------------------------------------------------------------------------------------------
FORM findmainmessageclass USING value(programname)
                                      messageclass.

  SELECT SINGLE msgid
                FROM trdire INTO messageclass
                WHERE report = programname.
ENDFORM.                                                                           "findMainMessageClass

*-------------------------------------------------------------------------------------------------------
* retrieveClasses...    find classes and sub objects from SAP DB
*-------------------------------------------------------------------------------------------------------
FORM retrieveclasses USING ilocclasses LIKE iclasses[]
                           ilocfunctions LIKE ifunctions[]
                           rangeclass LIKE soclassname[]
                           rangeauthor LIKE soauthor[]
                           value(custnamerange)
                           value(alsomodifiedbyauthor)
                           value(customerprogsonly)
                           value(getmessages)
                           value(gettextelements)
                           value(getcustdictstructures)
                           value(getfunctions)
                           value(getincludes)
                           value(gettransformations)
                           value(recursivefuncsearch)
                           value(recursiveincludesearch)
                           value(recursiveclasssearch)
                           value(language)
                           value(solocpackage) LIKE sopack[].

  DATA: warangeclass LIKE LINE OF rangeclass.
  DATA: waclass LIKE LINE OF ilocclasses[].

  IF rangeclass[] IS INITIAL.
*   We are finding all programs by an author
    PERFORM findallclassesforauthor USING ilocclasses[]
                                           rangeclass[]
                                           rangeauthor[]
                                           custnamerange
                                           alsomodifiedbyauthor
                                           customerprogsonly
                                           language.
  ELSE.
    READ TABLE rangeclass INDEX 1 INTO warangeclass.
    IF warangeclass-low CS asterix.
      PERFORM findclassesbywildcard USING ilocclasses[]
                                          rangeclass[]
                                          rangeauthor[]
                                          custnamerange
                                          customerprogsonly
                                          language.
    ELSE.
      PERFORM checkclassdoesexist USING ilocclasses[]
                                        rangeclass[].
    ENDIF.
  ENDIF.

* Check the package
  IF NOT solocpackage[] IS INITIAL.
    LOOP AT ilocclasses INTO waclass.
      SELECT SINGLE obj_name
             FROM tadir
             INTO waclass-clsname
             WHERE pgmid = 'R3TR'
               AND object = 'CLAS'
               AND obj_name = waclass-clsname
               AND devclass IN solocpackage[].
      IF sy-subrc <> 0.
        DELETE ilocclasses.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Find extra items
  IF NOT ilocclasses[] IS INITIAL.
    PERFORM scanforadditionalclassstuff USING ilocclasses[]
                                              ilocfunctions[]
                                              gettextelements
                                              getmessages
                                              getcustdictstructures
                                              getfunctions
                                              getincludes
                                              gettransformations
                                              customerprogsonly
                                              custnamerange
                                              recursiveincludesearch
                                              recursivefuncsearch
                                              recursiveclasssearch
                                              solocpackage[].
  ENDIF.
ENDFORM.                                                                                "retrieveClasses

*-------------------------------------------------------------------------------------------------------
*  findAllClassesForAuthor...
*-------------------------------------------------------------------------------------------------------
FORM findallclassesforauthor USING ilocclass LIKE iclasses[]
                                   rangeclass LIKE soclassname[]
                                   rangeauthor LIKE soauthor[]
                                   value(custnamerange)
                                   value(alsomodifiedbyauthor)
                                   value(customerclassesonly)
                                   value(language).

  DATA: altcustomernamerange TYPE string.

* build up the customer name range used for select statements
  CONCATENATE custnamerange '%' INTO altcustomernamerange.

* select by name and author
  IF NOT alsomodifiedbyauthor IS INITIAL.
*   Classes modified by author
    IF customerclassesonly IS INITIAL.
*     Select all classes
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND langu = language
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).

      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
               AND langu = language
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ELSE.
*     Select only customer specific classes
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND ( clsname LIKE altcustomernamerange
                     OR clsname LIKE 'Z%'
                     OR clsname LIKE 'Y%')
               AND langu = language
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).

      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND ( clsname LIKE altcustomernamerange
                       OR clsname LIKE 'Z%'
                       OR clsname LIKE 'Y%')
                 AND langu = language
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ENDIF.
  ELSE.
*   Programs created by author
    IF customerclassesonly IS INITIAL.
*     Select all classes
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND langu = language
               AND author IN rangeauthor
               AND version = '1'
               AND ( state = '0' OR state = '1' ).

      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND langu = language
                 AND author IN rangeauthor
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ELSE.
*     Select only customer specific classes
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND ( clsname LIKE altcustomernamerange
                     OR clsname LIKE 'Z%'
                     OR clsname LIKE 'Y%')
               AND langu = language
               AND author IN rangeauthor
               AND version = '1'
               AND ( state = '0' OR state = '1' ).

      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND ( clsname LIKE altcustomernamerange
                       OR clsname LIKE 'Z%'
                       OR clsname LIKE 'Y%')
                 AND langu = language
                 AND author IN rangeauthor
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                                                                        "findAllClassesForAuthor

*-------------------------------------------------------------------------------------------------------
*  findClassesByWildcard...  Find classes using a wildcard search
*-------------------------------------------------------------------------------------------------------
FORM findclassesbywildcard USING ilocclass LIKE iclasses[]
                                 rangeclass LIKE soclassname[]
                                 value(rangeauthor) LIKE soauthor[]
                                 value(custnamerange)
                                 value(customerclassesonly)
                                 value(language).

  DATA: altcustomernamerange TYPE string.

  IF customerclassesonly IS INITIAL.
*   Searching for customer and SAP classes
    IF custnamerange <> '^'.
*     build up the customer name range used for select statements
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND clsname LIKE custnamerange
               AND langu = language
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).
      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND clsname LIKE custnamerange
                 AND langu = language
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ELSE.
*     Searching using normal name ranges
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND langu = language
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).
      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND langu = language
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ENDIF.
  ELSE.
*   searching for only customer classes
    IF custnamerange <> '^'.
*     build up the customer name range used for select statements
      CONCATENATE custnamerange '%' INTO altcustomernamerange.

      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND clsname LIKE custnamerange
               AND langu = language
               AND ( clsname LIKE 'ZC%' OR clsname LIKE 'YC%' )
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).
      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND langu = language
                 AND ( clsname LIKE 'ZC%' OR clsname LIKE 'YC%' )
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ELSE.
*     Searching using normal name ranges
      SELECT clsname descript msg_id
             FROM vseoclass
             APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
             WHERE clsname IN rangeclass
               AND ( clsname LIKE 'ZC%' OR clsname LIKE 'YC%' )
               AND ( author IN rangeauthor OR changedby IN rangeauthor )
               AND version = '1'
               AND ( state = '0' OR state = '1' ).
      IF sy-subrc <> 0.
        SELECT clsname descript msg_id
               FROM vseoclass
               APPENDING CORRESPONDING FIELDS OF TABLE ilocclass
               WHERE clsname IN rangeclass
                 AND ( clsname LIKE 'ZC%' OR clsname LIKE 'YC%' )
                 AND ( author IN rangeauthor OR changedby IN rangeauthor )
                 AND version = '0'
                 AND ( state = '0' OR state = '1' ).
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                                                                          "findClassesByWildcard

*-------------------------------------------------------------------------------------------------------
*  checkClassDoesExist...
*-------------------------------------------------------------------------------------------------------
FORM checkclassdoesexist USING ilocclass LIKE iclasses[]
                               rangeclass LIKE soclassname[].

  DATA: waclass TYPE tclass.

  SELECT SINGLE clsname descript msg_id
         FROM vseoclass
         INTO CORRESPONDING FIELDS OF waclass
         WHERE clsname IN rangeclass
           AND version = '1'
           AND ( state = '0' OR state = '1' ).

  IF sy-subrc <> 0.
    SELECT SINGLE clsname descript msg_id
         FROM vseoclass
         INTO CORRESPONDING FIELDS OF waclass
         WHERE clsname IN rangeclass
           AND version = '0'
           AND ( state = '0' OR state = '1' ).
  ENDIF.

  IF NOT waclass-clsname IS INITIAL.
    APPEND waclass TO ilocclass.
  ENDIF.
ENDFORM.                                                                            "checkClassDoesExist

*-------------------------------------------------------------------------------------------------------
*  scanForAdditionalClassStuff...
*-------------------------------------------------------------------------------------------------------
FORM scanforadditionalclassstuff USING ilocclasses LIKE iclasses[]
                                       ilocfunctions LIKE ifunctions[]
                                       value(gettextelements)
                                       value(getmessages)
                                       value(getcustdictstructures)
                                       value(getfunctions)
                                       value(getincludes)
                                       value(gettransformations)
                                       value(customeronly)
                                       value(customernamerange)
                                       value(recursiveincludesearch)
                                       value(recursivefuncsearch)
                                       value(recursiveclasssearch)
                                       value(solocpackage) LIKE sopack[].

  DATA: waclass TYPE tclass.
  DATA: wamethod TYPE tmethod.
  DATA: mytabix TYPE sytabix.
  DATA: scanningforclasses TYPE abap_bool VALUE false.
  DATA: classnewlines TYPE i VALUE 0.
  DATA: classcurrentlines TYPE i VALUE 0.

  LOOP AT ilocclasses INTO waclass WHERE scanned IS INITIAL.
*  Once we have a list of all the classes we need to loop round them an select all the other objects
    mytabix = sy-tabix.
    PERFORM findclassdetails USING waclass-clsname
                                   waclass
                                   ilocfunctions[]
                                   gettextelements
                                   getmessages
                                   getfunctions
                                   getcustdictstructures
                                   gettransformations
                                   customeronly
                                   customernamerange.

*   Set the scanned class so we do not check them again when running recursively.
    waclass-scanned = 'X'.
    MODIFY ilocclasses FROM waclass INDEX mytabix.
  ENDLOOP.

* Now we have all the classes and details we need to find extra classes
  IF NOT recursiveclasssearch IS INITIAL.
    classcurrentlines = lines( ilocclasses ).
    LOOP AT ilocclasses INTO waclass.
*     Don't try and find any other details for an exception class
      IF ( waclass-clsname NS 'ZCX_' OR waclass-clsname NS 'CX_'  ).
*       Find any classes defined in the main class definition
        PERFORM scanforclasses USING waclass-privateclasskey
                                     waclass-clsname
                                     customeronly
                                     customernamerange
                                     ilocclasses[]
                                     solocpackage[].

        PERFORM scanforclasses USING waclass-publicclasskey
                                     waclass-clsname
                                     customeronly
                                     customernamerange
                                     ilocclasses[]
                                     solocpackage[].

        PERFORM scanforclasses USING waclass-protectedclasskey
                                     waclass-clsname
                                     customeronly
                                     customernamerange
                                     ilocclasses[]
                                     solocpackage[].

        LOOP AT waclass-imethods INTO wamethod.
*         Find any classes defined in any of the methods
          PERFORM scanforclasses USING wamethod-methodkey
                                       waclass-clsname
                                       customeronly
                                       customernamerange
                                       ilocclasses[]
                                       solocpackage[].
        ENDLOOP.
      ENDIF.
    ENDLOOP.

*   We have a list of all the classes so lets go and find their details
    classnewlines = lines( ilocclasses ).
    IF classnewlines > classcurrentlines.
      PERFORM scanforadditionalclassstuff USING ilocclasses[]
                                                ilocfunctions[]
                                                gettextelements
                                                getmessages
                                                getcustdictstructures
                                                getfunctions
                                                getincludes
                                                gettransformations
                                                customeronly
                                                customernamerange
                                                recursiveincludesearch
                                                recursivefuncsearch
                                                recursiveclasssearch
                                                solocpackage[].
    ENDIF.
  ENDIF.
ENDFORM.                                                                   "scanForAdditionalClassStuff

*-------------------------------------------------------------------------------------------------------
*  findClassDetails...
*-------------------------------------------------------------------------------------------------------
FORM findclassdetails USING value(classname)
                                  waclass TYPE tclass
                                  ilocfunctions LIKE ifunctions[]
                                  value(gettextelements)
                                  value(getmessages)
                                  value(getfunctions)
                                  value(getcustdictstructures)
                                  value(gettransformations)
                                  value(customeronly)
                                  value(customernamerange).

  DATA: iemptyselectiontexts TYPE STANDARD TABLE OF ttexttable.
  DATA: mytabix TYPE sytabix.
  DATA: wamethod TYPE tmethod.
  DATA: rnblankauthor LIKE soauthor[].
  DATA: rnblankpackage LIKE sopack[].
  DATA: wainterface TYPE tinterface.

* Build up the keys we will use for finding data
  PERFORM buildclasskeys USING waclass.

  IF waclass-descript IS INITIAL.
    PERFORM findclassdescription USING classname
                                       waclass-descript.
  ENDIF.

* Find the class attributes.
  SELECT SINGLE exposure msg_id state clsfinal r3release
                FROM vseoclass
                INTO (waclass-exposure, waclass-msg_id, waclass-state,
                      waclass-clsfinal, waclass-r3release)
                WHERE clsname = waclass-clsname.

* Don't try and find any other details for an exception class
  IF ( waclass-clsname CS 'ZCX_' OR waclass-clsname CS 'CX_'  ).
*   Exception texts
    PERFORM findexceptiontexts USING waclass-publicclasskey
                                     waclass-iconcepts[].
    waclass-scanned = 'X'.
  ELSE.
    IF NOT gettextelements IS INITIAL.
*     Find the class texts from out of the database.
      PERFORM retrieveprogramtexts USING iemptyselectiontexts[]
                                         waclass-itextelements[]
                                         waclass-textelementkey.
    ENDIF.

*   Find any declared dictionary structures
    IF NOT getcustdictstructures IS INITIAL.
      PERFORM scanfortables USING waclass-privateclasskey
                                  customeronly
                                  customernamerange
                                  waclass-idictstruct[].

      PERFORM scanfortables USING waclass-publicclasskey
                                  customeronly
                                  customernamerange
                                  waclass-idictstruct[].

      PERFORM scanfortables USING waclass-protectedclasskey
                                  customeronly
                                  customernamerange
                                  waclass-idictstruct[].

      PERFORM scanfortables USING waclass-typesclasskey
                                  customeronly
                                  customernamerange
                                  waclass-idictstruct[].

      PERFORM scanforlikeortype USING waclass-privateclasskey
                                      customeronly
                                      customernamerange
                                      waclass-idictstruct[]
                                      waclass-itabletypes[].

      PERFORM scanforlikeortype USING waclass-publicclasskey
                                      customeronly
                                      customernamerange
                                      waclass-idictstruct[]
                                      waclass-itabletypes[].

      PERFORM scanforlikeortype USING waclass-protectedclasskey
                                      customeronly
                                      customernamerange
                                      waclass-idictstruct[]
                                      waclass-itabletypes[].

      PERFORM scanforlikeortype USING waclass-typesclasskey
                                      customeronly
                                      customernamerange
                                      waclass-idictstruct[]
                                      waclass-itabletypes[].
    ENDIF.

*   Find all the interfaces used in this class
    PERFORM findclassinterfaces USING classname
                                      waclass-iinterfaces[].

*   Find all the methods defined by the interfaces
    PERFORM findinterfacemethods USING classname
                                       waclass-iinterfaces[]
                                       waclass-imethods[].

*   Methods
*   Find all the methods for this class
    PERFORM findclassmethods USING classname
                                   waclass-imethods[].

    LOOP AT waclass-imethods[] INTO wamethod.
      mytabix = sy-tabix.
*     Find individual messages
      IF NOT getmessages IS INITIAL.
        PERFORM scanformessages USING wamethod-methodkey
                                      waclass-msg_id
                                      waclass-imessages[].
      ENDIF.

      IF NOT getcustdictstructures IS INITIAL.
*       Find any declared dictionary structures
        PERFORM scanfortables USING wamethod-methodkey
                                    customeronly
                                    customernamerange
                                    waclass-idictstruct[].

        PERFORM scanforlikeortype USING wamethod-methodkey
                                        customeronly
                                        customernamerange
                                        waclass-idictstruct[]
                                        waclass-itabletypes[].
      ENDIF.

      IF NOT getfunctions IS INITIAL.
        PERFORM scanforfunctions USING wamethod-methodkey
                                       waclass-clsname
                                       space
                                       space
                                       customeronly
                                       customernamerange
                                       ilocfunctions[].
      ENDIF.

*     Find any XSLT Transformations
      IF NOT gettransformations IS INITIAL.
        PERFORM scanfortransformations USING wamethod-methodkey
                                             customeronly
                                             customernamerange
                                             waclass-itransformations[].
      ENDIF.

      MODIFY waclass-imethods FROM wamethod INDEX mytabix.
    ENDLOOP.

*   If the class has specified a message class but were unable to find any specific messages
*   then retrieve the whole message class.
    IF ( NOT waclass-msg_id IS INITIAL AND waclass-imessages[] IS INITIAL ).
      PERFORM retrievemessageclass USING waclass-imessages[]
                                         rnblankauthor[]
                                         waclass-msg_id
                                         pmlang
                                         ''
                                         rnblankpackage[].
    ENDIF.
  ENDIF.
ENDFORM.                                                                               "findClassDetails

*----------------------------------------------------------------------------------------------------------------------
* Find all interface methods used by the class
*----------------------------------------------------------------------------------------------------------------------
FORM findinterfacemethods USING value(classname)
                                      ilocinterfaces LIKE dumiinterfaces[]
                                      ilocmethods LIKE dumimethods[].

  TYPES: BEGIN OF tintmethod,
           interfacename LIKE vseomethod-clsname,
           cmpname LIKE vseomethod-cmpname,
           exposure LIKE vseomethod-exposure,
         END OF tintmethod.
  DATA: wamethod TYPE tmethod.
  DATA: wainterface LIKE LINE OF ilocinterfaces.
  DATA: iintmethod TYPE STANDARD TABLE OF tintmethod WITH HEADER LINE.

  LOOP AT ilocinterfaces INTO wainterface.
    SELECT a~clsname AS interfacename
           a~cmpname
           b~exposure
           APPENDING TABLE iintmethod
           FROM seocompo AS a
           INNER JOIN seocompodf AS b
             ON a~clsname = b~clsname
             AND a~cmpname = b~cmpname
           WHERE a~clsname = wainterface-interfacename.
  ENDLOOP.

  LOOP AT iintmethod.
    CONCATENATE iintmethod-interfacename '~' iintmethod-cmpname INTO wamethod-cmpname.
    wamethod-exposure = iintmethod-exposure.

    SELECT SINGLE descript
           FROM seocompotx
           INTO wamethod-descript
           WHERE clsname = iintmethod-interfacename
             AND cmpname = iintmethod-cmpname
             AND langu = pmlang.

    PERFORM findmethodkey USING classname
                                wamethod-cmpname
                                wamethod-methodkey.

    IF NOT wamethod-methodkey IS INITIAL.
      APPEND wamethod TO ilocmethods.
    ENDIF.

    CLEAR wamethod.
  ENDLOOP.
ENDFORM.                    "findInterfaceMethods

*----------------------------------------------------------------------------------------------------------------------
*   Check to see if their are any interfaces being used by this class
*----------------------------------------------------------------------------------------------------------------------
FORM findclassinterfaces USING value(classname)
                                     ilocinterfaces LIKE dumiinterfaces[].

  DATA: isinheritance TYPE abap_bool VALUE abap_true.
  DATA: iinterfaces TYPE STANDARD TABLE OF vseoimplem WITH HEADER LINE.
  DATA: walocinterface LIKE LINE OF ilocinterfaces.

  SELECT * FROM vseoimplem
           INTO TABLE iinterfaces
           WHERE clsname = classname.

  WHILE isinheritance = abap_true.
    PERFORM findclassparent USING classname
                                  classname.

    IF classname IS INITIAL.
      isinheritance = abap_false.
    ELSE.
      SELECT * FROM vseoimplem
               APPENDING TABLE iinterfaces
               WHERE clsname = classname.
    ENDIF.
  ENDWHILE.

  IF NOT iinterfaces[] IS INITIAL.
    SORT iinterfaces ASCENDING BY refclsname.
    DELETE ADJACENT DUPLICATES FROM iinterfaces COMPARING refclsname.

    LOOP AT iinterfaces.
      walocinterface-interfacename = iinterfaces-refclsname.
      APPEND walocinterface TO ilocinterfaces.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "findClassInterfaces

*----------------------------------------------------------------------------------------------------------------------
*  Find the parent of the current class
*----------------------------------------------------------------------------------------------------------------------
FORM findclassparent USING value(classname)
                                 parentclassname.

  DATA: wainheritance TYPE seor_inheritance_r.
  DATA: clskey TYPE seoclskey.

  clskey-clsname = classname.

  CALL FUNCTION 'SEO_INHERITANC_READ'
    EXPORTING
      clskey             = clskey
      version            = seoc_version_active
    IMPORTING
      inheritance        = wainheritance
*     redefinitions      = redefinitions
    EXCEPTIONS
      class_not_existing = 1.

  parentclassname = wainheritance-refclsname.
ENDFORM.                    "findClassParent

*-------------------------------------------------------------------------------------------------------
*  buildClassKeys...   Finds the title text of a class.
*-------------------------------------------------------------------------------------------------------
FORM buildclasskeys USING waclass TYPE tclass.

  DATA: classnamelength TYPE i.
  DATA: loops TYPE i.

  classnamelength = strlen( waclass-clsname ).

  cl_oo_classname_service=>get_pubsec_name( EXPORTING clsname = waclass-clsname
                                            RECEIVING result = waclass-publicclasskey ).

  cl_oo_classname_service=>get_prisec_name( EXPORTING clsname = waclass-clsname
                                            RECEIVING result = waclass-privateclasskey ).

  cl_oo_classname_service=>get_prosec_name( EXPORTING clsname = waclass-clsname
                                            RECEIVING result = waclass-protectedclasskey ).


* Text element key - length of text element key has to be 32 characters.
  loops = 30 - classnamelength.
  waclass-textelementkey = waclass-clsname.
  DO loops TIMES.
    CONCATENATE waclass-textelementkey '=' INTO waclass-textelementkey.
  ENDDO.
* Save this for later.
  CONCATENATE waclass-textelementkey 'CP' INTO waclass-textelementkey.

* Types Class key - length of class name has to be 32 characters.
  loops = 30 - classnamelength.
  waclass-typesclasskey = waclass-clsname.
  DO loops TIMES.
    CONCATENATE waclass-typesclasskey '=' INTO waclass-typesclasskey.
  ENDDO.
* Save this for later
  CONCATENATE waclass-typesclasskey 'CT' INTO waclass-typesclasskey.
ENDFORM.                                                                                 "buildClassKeys

*-------------------------------------------------------------------------------------------------------
*  findClassDescription...   Finds the title text of a class.
*-------------------------------------------------------------------------------------------------------
FORM findclassdescription USING value(classname)
                                      titletext.

  SELECT SINGLE descript
                FROM vseoclass
                INTO titletext
                WHERE clsname = classname
                  AND langu = pmlang.
  IF sy-subrc <> 0.
    SELECT SINGLE descript
                  FROM vseoclass
                  INTO titletext
                  WHERE clsname = classname.
  ENDIF.
ENDFORM.                                                                           "findClassDescription

*-------------------------------------------------------------------------------------------------------
*  findExceptionTexts...   Fiond the texts of an exception class.
*-------------------------------------------------------------------------------------------------------
FORM findexceptiontexts USING publicclasskey
                              iconcepts LIKE dumiconcepts[].

  DATA: castclassname TYPE program.
  DATA: itemplines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: watokens TYPE stokes.
  DATA: wacurrenttoken TYPE stokes.
  DATA: waconcept LIKE LINE OF iconcepts.
  DATA: tokenlength TYPE i.
  DATA: myrow TYPE i.

  castclassname = publicclasskey.
  READ REPORT castclassname INTO itemplines.

  APPEND 'CONSTANTS' TO ikeywords.
  SCAN ABAP-SOURCE itemplines TOKENS INTO itokens STATEMENTS INTO istatements KEYWORDS FROM ikeywords.

  DELETE itokens WHERE str = 'CONSTANTS'.
  DELETE itokens WHERE str = 'VALUE'.
  DELETE itokens WHERE str = 'TYPE'.

  LOOP AT itokens INTO watokens WHERE str = 'SOTR_CONC'.
*   The loop before holds the constant name
    myrow = sy-tabix - 1.
    READ TABLE itokens INDEX myrow INTO wacurrenttoken.
    waconcept-constname = wacurrenttoken-str.

*   The loop after holds the constant name
    myrow = myrow + 2.
    READ TABLE itokens INDEX myrow INTO wacurrenttoken.
    tokenlength = strlen( wacurrenttoken-str ).
    IF tokenlength = 34.
*     Most likely an exception text.
      REPLACE ALL OCCURRENCES OF '''' IN wacurrenttoken-str WITH ' ' .
      waconcept-concept = wacurrenttoken-str.
      APPEND waconcept TO iconcepts.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "findExceptionTexts

*-------------------------------------------------------------------------------------------------------
*  findClassMethods...   Finds the methods of a class.
*-------------------------------------------------------------------------------------------------------
FORM findclassmethods USING value(classname)
                            ilocmethods LIKE dumimethods[].

  DATA: imethods TYPE STANDARD TABLE OF tmethod WITH HEADER LINE.
  DATA: iredefinedmethods TYPE STANDARD TABLE OF seoredef WITH HEADER LINE.
  DATA: originalclassname TYPE seoclsname.
  DATA: wamethod LIKE LINE OF imethods.

  SELECT cmpname descript exposure
         FROM vseomethod
         INTO CORRESPONDING FIELDS OF TABLE imethods
           WHERE clsname = classname
             AND version = '1'
             AND langu = pmlang
             AND ( state = '0' OR state = '1' ).

  IF sy-subrc <> 0.
    SELECT cmpname descript exposure
           FROM vseomethod
           INTO CORRESPONDING FIELDS OF TABLE imethods
           WHERE clsname = classname
             AND version = '0'
             AND langu = pmlang
             AND ( state = '0' OR state = '1' ).
  ENDIF.

  SELECT *
         FROM seoredef
         INTO TABLE iredefinedmethods
         WHERE clsname = classname
           AND version = '1'.

*  For Each method we must find the original class the method was created in
  LOOP AT iredefinedmethods.
    PERFORM findredefinitionclass USING iredefinedmethods-refclsname
                                        iredefinedmethods-mtdname
                                        originalclassname.

    wamethod-cmpname = iredefinedmethods-mtdname.

    SELECT SINGLE descript exposure
        FROM vseomethod
        INTO CORRESPONDING FIELDS OF  wamethod
          WHERE clsname = originalclassname
            AND cmpname = iredefinedmethods-mtdname
            AND version = '1'
            AND langu = pmlang
            AND ( state = '0' OR state = '1' ).

    CONCATENATE `Redefined: ` wamethod-descript INTO wamethod-descript.
    APPEND wamethod TO imethods.
  ENDLOOP.

* Find the method key so that we can acces the source code later
  LOOP AT imethods.
    PERFORM findmethodkey USING classname
                                imethods-cmpname
                                imethods-methodkey.
    APPEND imethods TO ilocmethods.
  ENDLOOP.
ENDFORM.                                                                               "findClassMethods

*-------------------------------------------------------------------------------------------------------
* findRedefinitionClass... find the original class the method was redefined from
*-------------------------------------------------------------------------------------------------------
FORM findredefinitionclass USING value(redefinedclassname) TYPE seoclsname
                                 value(methodname) TYPE seocpdname
                                       originalclassname TYPE seoclsname.

  DATA: waredef TYPE seoredef.

  SELECT SINGLE *
         FROM seoredef
         INTO waredef
         WHERE refclsname = redefinedclassname
           AND mtdname = methodname.

  IF sy-subrc = 0.
*   There is a higher class still.
    originalclassname = waredef-refclsname.
    PERFORM findredefinitionclassrecur USING waredef-refclsname
                                             waredef-mtdname
                                             originalclassname.
  ELSE.
*   We are at the higher class.
    originalclassname = waredef-refclsname.
  ENDIF.
ENDFORM.                    "findRedefinitionClass

*-------------------------------------------------------------------------------------------------------
* findRedefinitionClassRecur... Recursively find the original class the method was redefined from
*-------------------------------------------------------------------------------------------------------
FORM findredefinitionclassrecur USING value(redefinedclassname) TYPE seoclsname
                                 value(methodname) TYPE seocpdname
                                       originalclassname TYPE seoclsname.

  DATA: waredef TYPE seoredef.

  SELECT SINGLE *
         FROM seoredef
         INTO waredef
         WHERE clsname = redefinedclassname
           AND mtdname = methodname.

  IF sy-subrc = 0.
*   There is a higher class still.
    originalclassname = waredef-refclsname.
    PERFORM findredefinitionclassrecur USING waredef-refclsname
                                             waredef-mtdname
                                             originalclassname.
  ENDIF.
ENDFORM.                    "findRedefinitionClassRecur

*-------------------------------------------------------------------------------------------------------
* findMethodKey... find the unique key which identifes this method
*-------------------------------------------------------------------------------------------------------
FORM findmethodkey USING value(classname)
                         value(methodname)
                               methodkey.

  DATA: methodid TYPE seocpdkey.
  DATA: locmethodkey TYPE program.

  methodid-clsname = classname.
  methodid-cpdname = methodname.

  cl_oo_classname_service=>get_method_include( EXPORTING mtdkey = methodid
                                               RECEIVING result = locmethodkey
                                               EXCEPTIONS class_not_existing = 1
                                                          method_not_existing = 2 ).

  methodkey = locmethodkey.
ENDFORM.                                                                                  "findMethodKey

*-------------------------------------------------------------------------------------------------------
* scanForMessages... Search each program for messages
*-------------------------------------------------------------------------------------------------------
FORM scanformessages USING value(programname)
                           value(mainmessageclass)
                                 ilocmessages LIKE imessages[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: wamessage TYPE tmessage.
  DATA: wamessagecomparison TYPE tmessage.
  DATA: watokens TYPE stokes.
  DATA: nextline TYPE i.
  DATA: stringlength TYPE i VALUE 0.
  DATA: workingonmessage TYPE abap_bool VALUE false.
  DATA: castprogramname TYPE program.

* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO iincludelines.

  APPEND message TO ikeywords.
  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements KEYWORDS FROM ikeywords.

  CLEAR iincludelines[].

  LOOP AT itokens.
    IF itokens-str = message.
      workingonmessage = true.
      CONTINUE.
    ENDIF.

    IF workingonmessage = true.
      stringlength = strlen( itokens-str ).

*     Message declaration 1
      IF stringlength = 4 AND itokens-str+0(1) CA sy-abcde.
        wamessage-msgnr = itokens-str+1(3).
        wamessage-arbgb = mainmessageclass.
      ELSE.
        IF itokens-str CS '''' OR itokens-str CS '`'.
*         Message declaration 2
          TRANSLATE itokens-str USING ''' '.
          TRANSLATE itokens-str USING '` '.
          CONDENSE itokens-str.
          SHIFT itokens-str LEFT DELETING LEADING space.
          wamessage-text = itokens-str.
          wamessage-arbgb = 'Hard coded'.
        ELSE.
          IF itokens-str = 'ID'.
*           Message declaration 3
            nextline = sy-tabix + 1.
            READ TABLE itokens INDEX nextline INTO watokens.
            TRANSLATE watokens-str USING ''' '.
            CONDENSE itokens-str.
            SHIFT watokens-str LEFT DELETING LEADING space.
            IF NOT watokens-str = 'SY-MSGID'.
              wamessage-arbgb = watokens-str.

              nextline = nextline + 4.
              READ TABLE itokens INDEX nextline INTO watokens.
              TRANSLATE watokens-str USING ''' '.
              CONDENSE watokens-str.
              SHIFT watokens-str LEFT DELETING LEADING space.
              wamessage-msgnr = watokens-str.
            ELSE.
              workingonmessage = false.
            ENDIF.
          ELSE.
            IF stringlength >= 5 AND itokens-str+4(1) = '('.
*              Message declaration 4
              wamessage-msgnr = itokens-str+1(3).
              SHIFT itokens-str LEFT UP TO '('.
              REPLACE '(' INTO itokens-str WITH space.
              REPLACE ')' INTO itokens-str WITH space.
              CONDENSE itokens-str.
              wamessage-arbgb = itokens-str.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

*      find the message text
      IF NOT wamessage-arbgb IS INITIAL AND NOT wamessage-msgnr IS INITIAL AND wamessage-text IS INITIAL.
        SELECT SINGLE text
                      FROM t100
                      INTO wamessage-text
                      WHERE sprsl = pmlang
                        AND arbgb = wamessage-arbgb
                        AND msgnr = wamessage-msgnr.
      ENDIF.

*      Append the message
      IF NOT wamessage IS INITIAL.
        IF NOT wamessage-text IS INITIAL.
*          Don't append the message if we already have it listed
          READ TABLE ilocmessages WITH KEY arbgb = wamessage-arbgb
                                           msgnr = wamessage-msgnr
                                           INTO wamessagecomparison.
          IF sy-subrc <> 0.
            APPEND wamessage TO ilocmessages.
          ENDIF.
        ENDIF.
        CLEAR wamessage.
        workingonmessage = false.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                 "scanForMessages

*-------------------------------------------------------------------------------------------------------
* scanForTables... Search each program for dictionary tables
*-------------------------------------------------------------------------------------------------------
FORM scanfortables USING value(programname)
                         value(customeronly)
                         value(customernamerange)
                               ilocdictionary LIKE idictionary[].

  DATA: iincludelines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itokens TYPE STANDARD TABLE OF stokes WITH HEADER LINE.
  DATA: istatements TYPE STANDARD TABLE OF sstmnt WITH HEADER LINE.
  DATA: ikeywords TYPE STANDARD TABLE OF text20 WITH HEADER LINE.
  DATA: wadictionary TYPE tdicttable.
  DATA: wadictionarycomparison TYPE tdicttable.
  DATA: castprogramname TYPE program.

* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO iincludelines.

  APPEND tables TO ikeywords.

  SCAN ABAP-SOURCE iincludelines TOKENS INTO itokens WITH INCLUDES STATEMENTS INTO istatements KEYWORDS FROM ikeywords.
  CLEAR iincludelines[].

  SORT itokens ASCENDING BY str.
  DELETE itokens WHERE str = tables.

  LOOP AT itokens.
    IF NOT customeronly IS INITIAL.
      TRY.
          CASE itokens-str+0(1).
            WHEN 'Y' OR 'Z' OR customernamerange.
            WHEN OTHERS.
              CONTINUE.
          ENDCASE.
*        if ( iTokens-str+0(1) <> 'Y' or iTokens-str+0(1) <> 'Z' or iTokens-str ns customerNameRange ).
*          continue.
*        endif.
        CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
      ENDTRY.
    ENDIF.

    wadictionary-tablename = itokens-str.
*   Don't append the object if we already have it listed
    READ TABLE ilocdictionary INTO wadictionarycomparison WITH KEY tablename = wadictionary-tablename.
    IF sy-subrc <> 0.
      PERFORM findtabledescription USING wadictionary-tablename
                                         wadictionary-tabletitle.

      PERFORM findtabledefinition USING wadictionary-tablename
                                        wadictionary-istructure[].

      APPEND wadictionary TO ilocdictionary.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                 "scanForTables

*-------------------------------------------------------------------------------------------------------
*  findProgramScreenFlow...
*-------------------------------------------------------------------------------------------------------
FORM findprogramscreenflow USING waprogram TYPE tprogram.

  DATA: iflow TYPE STANDARD TABLE OF tscreenflow WITH HEADER LINE.

  CALL FUNCTION 'DYNPRO_PROCESSINGLOGIC'
    EXPORTING
      rep_name  = waprogram-progname
    TABLES
      scr_logic = iflow.

  SORT iflow ASCENDING BY screen.
  DELETE ADJACENT DUPLICATES FROM iflow COMPARING screen.
  IF waprogram-subc <> 'M'.
    DELETE iflow WHERE screen >= '1000' AND screen <= '1099'.
  ENDIF.

  LOOP AT iflow.
    APPEND iflow TO waprogram-iscreenflow.
  ENDLOOP.
ENDFORM.                                                                          "findProgramScreenFlow

*----------------------------------------------------------------------------------------------------------------------
*  findMainFunctionInclude...  Find the main include that contains the source code
*----------------------------------------------------------------------------------------------------------------------
FORM findmainfunctioninclude USING value(programname)
                                   value(functiongroup)
                                   value(functionincludeno)
                                         functionincludename.

  DATA: namespace TYPE string,
        iresults TYPE match_result_tab,
        waresult TYPE match_result,
        startingposition TYPE i.

  FIND ALL OCCURRENCES OF '/' IN functiongroup RESULTS iresults.
  IF sy-subrc = 0.
    READ TABLE iresults INDEX sy-tfill INTO waresult.
    startingposition = waresult-offset + 1.
    namespace = functiongroup+0(startingposition).
    functiongroup = functiongroup+startingposition.
  ENDIF.

  CONCATENATE namespace 'L' functiongroup 'U' functionincludeno INTO functionincludename.
ENDFORM.                                                                                       "findMainFunctionInclude

*----------------------------------------------------------------------------------------------------------------------
*  findFunctionTopInclude...  Find the top include for the function group
*----------------------------------------------------------------------------------------------------------------------
FORM findfunctiontopinclude USING value(programname)
                                  value(functiongroup)
                                        topincludename.

  DATA: namespace TYPE string,
        iresults TYPE match_result_tab,
        waresult TYPE match_result,
        startingposition TYPE i.

  FIND ALL OCCURRENCES OF '/' IN functiongroup RESULTS iresults.
  IF sy-subrc = 0.
    READ TABLE iresults INDEX sy-tfill INTO waresult.
    startingposition = waresult-offset + 1.
    namespace = functiongroup+0(startingposition).
    functiongroup = functiongroup+startingposition.
  ENDIF.

  CONCATENATE namespace 'L' functiongroup 'TOP' INTO topincludename.
ENDFORM.                                                                                        "findFunctionTopInclude

*-------------------------------------------------------------------------------------------------------
*  findFunctionScreenFlow...
*-------------------------------------------------------------------------------------------------------
FORM findfunctionscreenflow USING wafunction TYPE tfunction.

  DATA: iflow TYPE STANDARD TABLE OF tscreenflow WITH HEADER LINE.

  CALL FUNCTION 'DYNPRO_PROCESSINGLOGIC'
    EXPORTING
      rep_name  = wafunction-progname
    TABLES
      scr_logic = iflow.

  SORT iflow ASCENDING BY screen.
  DELETE ADJACENT DUPLICATES FROM iflow COMPARING screen.

  LOOP AT iflow.
    APPEND iflow TO wafunction-iscreenflow.
  ENDLOOP.
ENDFORM.                                                                          "findFunctionScreenFlow

*-------------------------------------------------------------------------------------------------------
* scanForLikeOrType... Look for any dictionary objects referenced by a like or type statement
*-------------------------------------------------------------------------------------------------------
FORM scanforlikeortype USING value(programname)
                             value(customeronly)
                             value(customernamerange)
                             ilocdictionary LIKE idictionary[]
                             iloctabletypes LIKE itabletypes[].

  DATA ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: head TYPE string.
  DATA: tail TYPE string.
  DATA: junk TYPE string.
  DATA: linetype TYPE string.
  DATA: linelength TYPE i VALUE 0.
  DATA: endofline TYPE abap_bool VALUE true.
  DATA: wadictionary TYPE tdicttable.
  DATA: wadictionarycomparison TYPE tdicttable.
  DATA: waline TYPE string.
  DATA: castprogramname TYPE program.


* Read the program code from the textpool.
  castprogramname = programname.
  READ REPORT castprogramname INTO ilines.

  LOOP AT ilines INTO waline.
*   Find custom tables.
    linelength = strlen( waline ).
    IF linelength > 0.
      IF waline(1) = asterix.
        CONTINUE.
      ENDIF.

      TRANSLATE waline TO UPPER CASE.

*     Determine the lineType.
      IF endofline = true.
        SHIFT waline UP TO like.
        IF sy-subrc = 0.
          linetype = like.
        ELSE.
          SHIFT waline UP TO type.
          IF sy-subrc = 0.
            FIND 'BEGIN OF' IN waline.
            IF sy-subrc <> 0.
              FIND 'END OF' IN waline.
              IF sy-subrc <> 0.
                FIND 'VALUE' IN waline.
                IF sy-subrc <> 0.
                  linetype = type.
                ENDIF.
              ENDIF.
            ENDIF.
          ELSE.
            SHIFT waline UP TO include.
            IF sy-subrc = 0.
              SPLIT waline AT space INTO junk ilines.
            ENDIF.

            SHIFT waline UP TO structure.
            IF sy-subrc = 0.
              linetype = structure.
            ELSE.
              CONTINUE.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        linetype = comma.
      ENDIF.

      CASE linetype.
        WHEN like OR type OR structure.
*         Work on the appropriate lineType
          SHIFT waline UP TO space.
          SHIFT waline LEFT DELETING LEADING space.
          IF waline CS table.
            SPLIT waline AT table INTO head tail.
            SPLIT tail AT 'OF' INTO head tail.
            waline = tail.
            SHIFT waline LEFT DELETING LEADING space.
            REPLACE ALL OCCURRENCES OF 'WITH HEADER LINE' IN waline WITH ''.
          ENDIF.

*         Are we only to download SAP dictionary structures.
          IF NOT customeronly IS INITIAL.
            TRY.
                IF waline+0(1) = 'Y' OR waline+0(1) = 'Z' OR waline CS customernamerange.
                ELSE.
                  linetype = ''.
                  CONTINUE.
                ENDIF.
              CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
            ENDTRY.
          ENDIF.

          IF waline CS comma.
            SPLIT waline AT comma INTO head tail.
            IF waline CS dash.
              SPLIT head AT dash INTO head tail.
            ENDIF.
            IF waline CS occurs.
              SPLIT waline AT space INTO head tail.
            ENDIF.
          ELSE.
            IF waline CS period.
              SPLIT waline AT period INTO head tail.
              IF waline CS dash.
                SPLIT head AT dash INTO head tail.
              ENDIF.
              IF waline CS occurs.
                SPLIT waline AT space INTO head tail.
              ENDIF.
            ELSE.
              SPLIT waline AT space INTO head tail.
              IF waline CS dash.
                SPLIT head AT dash INTO head tail.
              ENDIF.
            ENDIF.
          ENDIF.

          IF NOT head IS INITIAL.
            wadictionary-tablename = head.
*           Don't append the object if we already have it listed
            READ TABLE ilocdictionary INTO wadictionarycomparison
                                      WITH KEY tablename = wadictionary-tablename.
            IF sy-subrc <> 0.
              PERFORM findtabledescription USING wadictionary-tablename
                                                 wadictionary-tabletitle.

              PERFORM findtabledefinition USING wadictionary-tablename
                                                wadictionary-istructure[].

*             Only append if the item is a table and not a structure or data element
              IF wadictionary-istructure[] IS INITIAL.
*               Not a table, but is it a table type?
                PERFORM checkandaddtabletype USING wadictionary-tablename
                                                   iloctabletypes[].
              ELSE.
*               It is a table
                APPEND wadictionary TO ilocdictionary.
              ENDIF.
            ENDIF.
            CLEAR wadictionary.
          ENDIF.

          linetype = ''.
      ENDCASE.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                              "scanForLikeOrType

*-------------------------------------------------------------------------------------------------------
*  displayStatus...
*-------------------------------------------------------------------------------------------------------
FORM displaystatus USING value(message)
                         value(delay).

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = 0
      text       = message
    EXCEPTIONS
      OTHERS     = 1.

  IF delay > 0.
    WAIT UP TO delay SECONDS.
  ENDIF.
ENDFORM.                                                                                  "displayStatus

*-------------------------------------------------------------------------------------------------------
*  removeLeadingZeros...
*-------------------------------------------------------------------------------------------------------
FORM removeleadingzeros CHANGING myvalue.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = myvalue
    IMPORTING
      output = myvalue
    EXCEPTIONS
      OTHERS = 1.
ENDFORM.                                                                             "removeLeadingZeros

*-------------------------------------------------------------------------------------------------------
* determineFrontendOPSystem.... Determine the frontend operating system type.
*-------------------------------------------------------------------------------------------------------
FORM determinefrontendopsystem USING separator
                                     operatingsystem.

  DATA: platformid TYPE i VALUE 0.

  CREATE OBJECT objfile.

  CALL METHOD objfile->get_platform
    RECEIVING
      platform             = platformid
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3.
  CASE platformid.
    WHEN objfile->platform_windows95
         OR objfile->platform_windows98
         OR objfile->platform_nt351
         OR objfile->platform_nt40
         OR objfile->platform_nt50
         OR objfile->platform_mac
         OR objfile->platform_os2
         OR 14.      "XP
      separator = '\'.
      operatingsystem = non_unix.
    WHEN OTHERS.
      separator = '/'.
      operatingsystem = unix.
  ENDCASE.
ENDFORM.                                                                      "determineFrontendOpSystem

*-------------------------------------------------------------------------------------------------------
* determineServerOPSystem.... Determine the server operating system type.
*-------------------------------------------------------------------------------------------------------
FORM determineserveropsystem USING separator
                                   serverfilesystem
                                   serveropsystem.

* Find the file system
  SELECT SINGLE filesys
                FROM opsystem
                INTO serverfilesystem
                WHERE opsys = sy-opsys.

  FIND 'WINDOWS' IN serverfilesystem IGNORING CASE.
  IF sy-subrc = 0.
    separator = '\'.
    serveropsystem = non_unix.
    serverfilesystem = 'Windows NT'.
  ELSE.
    FIND 'DOS' IN serverfilesystem IGNORING CASE.
    IF sy-subrc = 0.
      separator = '\'.
      serveropsystem = non_unix.
    ELSE.
      separator = '/'.
      serveropsystem = unix.
    ENDIF.
  ENDIF.
ENDFORM.                                                                        "determineServerOpSystem

*-------------------------------------------------------------------------------------------------------
* findExternalCommand.... Determine if the external command exists.  If it doesn't then disable the
*                         server input field
*-------------------------------------------------------------------------------------------------------
FORM findexternalcommand USING value(locserverfilesystem).

  DATA: castserveropsys TYPE syopsys.

  castserveropsys = locserverfilesystem.

  CALL FUNCTION 'SXPG_COMMAND_CHECK'
    EXPORTING
      commandname       = 'ZDTX_MKDIR'
      operatingsystem   = castserveropsys
    EXCEPTIONS
      command_not_found = 1
      OTHERS            = 0.

  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'PLOGICAL'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'PSERV'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'PPC'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    MESSAGE s000(oo) WITH 'Download to server disabled,' 'external command ZDTX_MKDIR not defined.'.
  ENDIF.
ENDFORM.                    "findExternalCommand

********************************************************************************************************
*****************************************DOWNLOAD ROUTINES**********************************************
********************************************************************************************************

*-------------------------------------------------------------------------------------------------------
* downloadDDStructures... download database objects to file
*-------------------------------------------------------------------------------------------------------
FORM downloadddstructures USING ilocdictionary LIKE idictionary[]
                                ilocdictionaryfilename LIKE idictfilename[]
                                value(pathname)
                                value(htmlfileextension)
                                value(subdir)
                                value(sorttablesasc)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.


  FIELD-SYMBOLS: <wadictionary> TYPE tdicttable.
  DATA: tablefilename TYPE string.
  DATA: tablefilenamewithpath TYPE string.
  DATA: ihtmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: newsubdirectory TYPE string.
  DATA: completesavepath TYPE string.
  DATA: wadictfilename LIKE LINE OF ilocdictionaryfilename.

  LOOP AT ilocdictionary ASSIGNING <wadictionary>.
    PERFORM buildfilename USING pathname
                                subdir
                                <wadictionary>-tablename
                                space
                                space
                                htmlfileextension
                                is_table
                                savetoserver
                                slashseparator
                                tablefilenamewithpath
                                tablefilename
                                newsubdirectory
                                completesavepath.

    READ TABLE ilocdictionaryfilename INTO wadictfilename WITH KEY tablename = <wadictionary>-tablename
                                                                   filename = completesavepath.
    IF sy-subrc <> 0.
*     Try and import a converted table to memory as it will be much quicker than converting it again
      IMPORT ihtmltable FROM MEMORY ID <wadictionary>-tablename.
      IF sy-subrc <> 0.
        IF displayprogressmessage = abap_true.
          CONCATENATE 'Converting table' <wadictionary>-tablename 'to html' INTO statusbarmessage SEPARATED BY space.
          PERFORM displaystatus USING statusbarmessage 0.
        ENDIF.

        PERFORM convertddtohtml USING <wadictionary>-istructure[]
                                      ihtmltable[]
                                      <wadictionary>-tablename
                                      <wadictionary>-tabletitle
                                      sorttablesasc
                                      addbackground.

        EXPORT ihtmltable TO MEMORY ID <wadictionary>-tablename.
      ENDIF.

      IF savetoserver IS INITIAL.
        PERFORM savefiletopc USING ihtmltable[]
                                   tablefilenamewithpath
                                   tablefilename
                                   space
                                   space
                                   displayprogressmessage.
      ELSE.
        PERFORM savefiletoserver USING ihtmltable[]
                                       tablefilenamewithpath
                                       tablefilename
                                       completesavepath
                                       displayprogressmessage
                                       locserverfilesystem.
      ENDIF.

      wadictfilename-tablename = <wadictionary>-tablename.
      wadictfilename-filename = completesavepath.
      APPEND wadictfilename TO ilocdictionaryfilename.
      CLEAR wadictfilename.
    ENDIF.

    CLEAR ihtmltable[].
  ENDLOOP.
ENDFORM.                                                                           "downloadDDStructures

*----------------------------------------------------------------------------------------------------------------------
*  downloadDDTableTypes
*----------------------------------------------------------------------------------------------------------------------
FORM downloadddtabletypes USING iloctabletypes LIKE itabletypes[]
                                iloctabletypefilename LIKE idictfilename[]
                                value(pathname)
                                value(htmlfileextension)
                                value(subdir)
                                value(sorttablesasc)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.

  FIELD-SYMBOLS: <watabletypes> LIKE LINE OF iloctabletypes.
  FIELD-SYMBOLS <wattfilename> LIKE LINE OF iloctabletypefilename[].
  DATA: tablefilename TYPE string.
  DATA: tablefilenamewithpath TYPE string.
  DATA: ihtmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: newsubdirectory TYPE string.
  DATA: completesavepath TYPE string.

  LOOP AT iloctabletypes ASSIGNING <watabletypes>.
    PERFORM buildfilename USING pathname
                                subdir
                                <watabletypes>-typename
                                space
                                space
                                htmlfileextension
                                is_table
                                savetoserver
                                slashseparator
                                tablefilenamewithpath
                                tablefilename
                                newsubdirectory
                                completesavepath.

    READ TABLE iloctabletypefilename INTO <wattfilename> WITH KEY tablename = <watabletypes>-typename
                                                                   filename = completesavepath.
    IF sy-subrc <> 0.
*     Try and import a converted table to memory as it will be much quicker than converting it again
      IMPORT ihtmltable FROM MEMORY ID <watabletypes>-typename.
      IF sy-subrc <> 0.
        IF displayprogressmessage = abap_true.
          CONCATENATE 'Converting table type' <watabletypes>-typename 'to html' INTO statusbarmessage SEPARATED BY space.
          PERFORM displaystatus USING statusbarmessage 0.
        ENDIF.

*    --     Need a specific routine for table types.  All data is in the table
        PERFORM converttabletypetohtml USING iloctabletypes[]
                                             ihtmltable[]
                                             <watabletypes>-typename
                                             <watabletypes>-ddtext
                                             sorttablesasc
                                             addbackground.

        IF savetoserver IS INITIAL.
          PERFORM savefiletopc USING ihtmltable[]
                                     tablefilenamewithpath
                                     tablefilename
                                     space
                                     space
                                     displayprogressmessage.
        ELSE.
          PERFORM savefiletoserver USING ihtmltable[]
                                         tablefilenamewithpath
                                         tablefilename
                                         completesavepath
                                         displayprogressmessage
                                         locserverfilesystem.
        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR ihtmltable[].
  ENDLOOP.
ENDFORM.                    "downloadDDTableTypes

*-------------------------------------------------------------------------------------------------------
* downloadMessageClass...
*-------------------------------------------------------------------------------------------------------
FORM downloadmessageclass USING ilocmessages LIKE imessages[]
                                value(messageclassname)
                                value(userfilepath)
                                value(fileextension)
                                value(htmlfileflag)
                                      subdir
                                value(customernamerange)
                                value(getincludes)
                                value(getdictstructures)
                                value(userhasselectedmessageclasses)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.

  DATA: htmlpagename TYPE string.
  DATA: newfilenameonly TYPE string.
  DATA: newfilenamewithpath TYPE string.
  DATA: ihtmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: newsubdirectory TYPE string.
  DATA: completesavepath TYPE string.

  PERFORM appendmessagestofile USING ilocmessages[]
                                     ihtmltable[]
                                     userhasselectedmessageclasses.


  CONCATENATE `message class ` messageclassname INTO htmlpagename.

  IF htmlfileflag IS INITIAL.
    APPEND '' TO ihtmltable.
    APPEND  '----------------------------------------------------------------------------------' TO ihtmltable.

    PERFORM buildfootermessage USING ihtmltable.
    APPEND ihtmltable.
  ELSE.
    PERFORM convertcodetohtml USING ihtmltable[]
                                    htmlpagename
                                    space
                                    is_messageclass
                                    ''
                                    false
                                    fileextension
                                    customernamerange
                                    getincludes
                                    getdictstructures
                                    addbackground.
  ENDIF.

  PERFORM buildfilename USING userfilepath
                              subdir
                              messageclassname
                              space
                              space
                              fileextension
                              is_messageclass
                              savetoserver
                              slashseparator
                              newfilenamewithpath
                              newfilenameonly
                              newsubdirectory
                              completesavepath.

  IF savetoserver IS INITIAL.
    PERFORM savefiletopc USING ihtmltable[]
                               newfilenamewithpath
                               newfilenameonly
                               space
                               space
                               displayprogressmessage.
  ELSE.
*     Save the file to the SAP server
    PERFORM savefiletoserver USING ihtmltable[]
                                   newfilenamewithpath
                                   newfilenameonly
                                   completesavepath
                                   displayprogressmessage
                                   locserverfilesystem.
  ENDIF.
ENDFORM.                                                                          "downloadMessageClass

*-------------------------------------------------------------------------------------------------------
*  appendMessagesToFile
*-------------------------------------------------------------------------------------------------------
FORM appendmessagestofile USING ilocmessages LIKE imessages[]
                                ilochtml LIKE dumihtml[]
                                value(userhasselectedmessageclasses).

  DATA: previousmessageid LIKE imessages-arbgb.
  FIELD-SYMBOLS: <wamessage> TYPE tmessage.
  DATA: wahtml TYPE string.

  SORT ilocmessages ASCENDING BY arbgb msgnr.

  IF NOT ilocmessages[] IS INITIAL.
    IF userhasselectedmessageclasses IS INITIAL.
*     Only add these extra lines if we are actually appending them to the end of some program code
      APPEND wahtml TO ilochtml.
      APPEND wahtml TO ilochtml.

      APPEND '*Messages' TO ilochtml.
      APPEND '*----------------------------------------------------------' TO ilochtml.
    ENDIF.

    LOOP AT ilocmessages ASSIGNING <wamessage>.
      IF ( <wamessage>-arbgb <> previousmessageid ).

        IF userhasselectedmessageclasses IS INITIAL.
*         Only add this extra lines if we are actually appending them to the end of some program code
          APPEND '*' TO ilochtml.
          CONCATENATE `* Message class: ` <wamessage>-arbgb INTO wahtml.
          APPEND wahtml TO ilochtml.
        ENDIF.

        previousmessageid = <wamessage>-arbgb.
        CLEAR wahtml.
      ENDIF.

      IF userhasselectedmessageclasses IS INITIAL.
*       Only add this extra lines if we are actually appending them to the end of some program code
        CONCATENATE '*' <wamessage>-msgnr `   ` <wamessage>-text INTO wahtml.
      ELSE.
        CONCATENATE <wamessage>-msgnr `   ` <wamessage>-text INTO wahtml.
      ENDIF.

      APPEND wahtml TO ilochtml.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                           "appendMessagesToFile

*-------------------------------------------------------------------------------------------------------
*  downloadFunctions...       Download function modules to file.
*-------------------------------------------------------------------------------------------------------
FORM downloadfunctions USING ilocfunctions LIKE ifunctions[]
                             ilocdictionaryfilename LIKE idictfilename[]
                             iloctabletypefilename LIKE itabletypefilename[]
                             value(userfilepath)
                             value(fileextension)
                             value(subdir)
                             value(downloaddocumentation)
                             value(converttohtml)
                             value(customernamerange)
                             value(getincludes)
                             value(getdictstruct)
                             value(textfileextension)
                             value(htmlfileextension)
                             value(sorttablesasc)
                             value(slashseparator)
                             value(savetoserver)
                             value(displayprogressmessage)
                             value(locserverfilesystem)
                             value(addbackground) TYPE abap_bool.

  DATA: mainsubdir TYPE string.
  DATA: incsubdir TYPE string.
  FIELD-SYMBOLS: <wafunction> TYPE tfunction.
  FIELD-SYMBOLS: <wainclude> TYPE tinclude.
  DATA: iemptytextelements TYPE STANDARD TABLE OF ttexttable.
  DATA: iemptyselectiontexts TYPE STANDARD TABLE OF ttexttable.
  DATA: iemptymessages TYPE STANDARD TABLE OF tmessage.
  DATA: iemptyguititles TYPE STANDARD TABLE OF tguititle.
  DATA: functiondocumentationexists TYPE abap_bool VALUE false.


  LOOP AT ilocfunctions ASSIGNING <wafunction>.
    IF subdir IS INITIAL.
      incsubdir = <wafunction>-functionname.
      mainsubdir = ''.
    ELSE.
      CONCATENATE subdir <wafunction>-functionname INTO incsubdir SEPARATED BY slashseparator.
      mainsubdir = subdir.
    ENDIF.

    IF NOT downloaddocumentation IS INITIAL.
      PERFORM downloadfunctiondocs USING <wafunction>-functionname
                                         <wafunction>-functiontitle
                                         userfilepath
                                         fileextension
                                         converttohtml
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         mainsubdir
                                         functiondocumentationexists
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download main source code
    PERFORM readfunctionanddownload USING <wafunction>-itextelements[]
                                          <wafunction>-iselectiontexts[]
                                          <wafunction>-imessages[]
                                          <wafunction>-functionname
                                          <wafunction>-functionmaininclude
                                          <wafunction>-functiontitle
                                          userfilepath
                                          fileextension
                                          mainsubdir
                                          converttohtml
                                          functiondocumentationexists
                                          customernamerange
                                          getincludes
                                          getdictstruct
                                          slashseparator
                                          savetoserver
                                          displayprogressmessage
                                          locserverfilesystem
                                          addbackground.

*   Download top include
    PERFORM readincludeanddownload USING iemptytextelements[]
                                         iemptyselectiontexts[]
                                         iemptymessages[]
                                         iemptyguititles[]
                                         <wafunction>-topincludename
                                         <wafunction>-functionname
                                         <wafunction>-functiontitle
                                         is_function
                                         userfilepath
                                         fileextension
                                         mainsubdir
                                         converttohtml
                                         customernamerange
                                         getincludes
                                         getdictstruct
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.

*   Download screens.
    IF NOT <wafunction>-iscreenflow[] IS INITIAL.
      PERFORM downloadscreens USING <wafunction>-iscreenflow[]
                                    <wafunction>-progname
                                    userfilepath
                                    textfileextension
                                    mainsubdir
                                    slashseparator
                                    savetoserver
                                    displayprogressmessage
                                    locserverfilesystem.
    ENDIF.

*   Download GUI titles
    IF NOT <wafunction>-iguititle[] IS INITIAL.
      PERFORM downloadguititles USING <wafunction>-iguititle
                                      userfilepath
                                      textfileextension
                                      mainsubdir
                                      slashseparator
                                      savetoserver
                                      displayprogressmessage
                                      locserverfilesystem.
    ENDIF.

*   Download all other includes
    LOOP AT <wafunction>-iincludes ASSIGNING <wainclude>.
      PERFORM readincludeanddownload USING iemptytextelements[]
                                           iemptyselectiontexts[]
                                           iemptymessages[]
                                           iemptyguititles[]
                                           <wainclude>-includename
                                           space
                                           <wainclude>-includetitle
                                           is_program
                                           userfilepath
                                           fileextension
                                           incsubdir
                                           converttohtml
                                           customernamerange
                                           getincludes
                                           getdictstruct
                                           slashseparator
                                           savetoserver
                                           displayprogressmessage
                                           locserverfilesystem
                                           addbackground.

    ENDLOOP.

*   Download all dictionary structures
    IF NOT <wafunction>-idictstruct[] IS INITIAL.
      PERFORM downloadddstructures USING <wafunction>-idictstruct[]
                                         ilocdictionaryfilename[]
                                         userfilepath
                                         htmlfileextension
                                         mainsubdir
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download all Table Types
    IF NOT <wafunction>-itabletypes[] IS INITIAL.
      PERFORM downloadddtabletypes USING <wafunction>-itabletypes[]
                                         iloctabletypefilename[]
                                         userfilepath
                                         htmlfileextension
                                         mainsubdir
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download Transformations
    IF NOT <wafunction>-itransformations[] IS INITIAL.
      PERFORM downloadxslt USING <wafunction>-itransformations[]
                                 userfilepath
                                 fileextension
                                 htmlfileextension
                                 textfileextension
                                 converttohtml
                                 customernamespace
                                 slashseparatortouse
                                 savetoserver
                                 subdir
                                 displayprogressmessage
                                 serverfilesystem
                                 addbackground.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                              "downloadFunctions

*-------------------------------------------------------------------------------------------------------
*   readIcludeAndDownload...
*-------------------------------------------------------------------------------------------------------
FORM readincludeanddownload USING iloctextelements LIKE dumitexttab[]
                                  ilocselectiontexts LIKE dumitexttab[]
                                  ilocmessages LIKE imessages[]
                                  ilocguititles LIKE dumiguititle[]
                                  value(programname)
                                  value(functionname)
                                  value(programdescription)
                                  value(overideprogtype)
                                  value(userfilepath)
                                  value(fileextension)
                                  value(additionalsubdir)
                                  value(converttohtml)
                                  value(customernamerange)
                                  value(getincludes)
                                  value(getdictstructures)
                                  value(slashseparator)
                                  value(savetoserver)
                                  value(displayprogressmessage)
                                  value(locserverfilesystem)
                                  value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: localfilenamewithpath TYPE string.
  DATA: localfilenameonly TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: objectname TYPE string.
  DATA: completesavepath TYPE string.

  READ REPORT programname INTO ilines.

* Download GUI titles for main program
  IF NOT ilocguititles[] IS INITIAL.
    PERFORM appendguititles USING ilocguititles[]
                                  ilines[].
  ENDIF.

* Download text elements for main program
  IF NOT iloctextelements[] IS INITIAL.
    PERFORM appendtextelements USING iloctextelements[]
                                     ilines[].
  ENDIF.

* Download selection texts for main program
  IF NOT ilocselectiontexts[] IS INITIAL.
    PERFORM appendselectiontexts USING ilocselectiontexts[]
                                       ilines[].
  ENDIF.

* Download messages classes for main program.
  IF NOT ilocmessages[] IS INITIAL.
    PERFORM appendmessagestofile USING ilocmessages[]
                                       ilines[]
                                       space.
  ENDIF.

  IF converttohtml IS INITIAL.
    APPEND '' TO ilines.
    APPEND '----------------------------------------------------------------------------------' TO ilines.
    PERFORM buildfootermessage USING ilines.
    APPEND ilines.
  ELSE.
    PERFORM convertcodetohtml USING ilines[]
                                    programname
                                    programdescription
                                    overideprogtype
                                    space
                                    space
                                    fileextension
                                    customernamerange
                                    getincludes
                                    getdictstructures
                                    addbackground.
  ENDIF.

  IF functionname IS INITIAL.
    objectname = programname.
  ELSE.
    objectname = functionname.
  ENDIF.

  PERFORM buildfilename USING userfilepath
                              additionalsubdir
                              objectname
                              space
                              programname
                              fileextension
                              overideprogtype
                              savetoserver
                              slashseparator
                              localfilenamewithpath
                              localfilenameonly
                              newsubdirectory
                              completesavepath.

  IF savetoserver IS INITIAL.
    PERFORM savefiletopc USING ilines[]
                               localfilenamewithpath
                               localfilenameonly
                               space
                               space
                               displayprogressmessage.
  ELSE.
    PERFORM savefiletoserver USING ilines[]
                                   localfilenamewithpath
                                   localfilenameonly
                                   completesavepath
                                   displayprogressmessage
                                   locserverfilesystem.
  ENDIF.
ENDFORM.                                                                         "readIncludeAndDownload

*-------------------------------------------------------------------------------------------------------
*   readClassAndDownload...
*-------------------------------------------------------------------------------------------------------
FORM readclassanddownload USING walocclass TYPE tclass
                                value(classname)
                                value(functionname)
                                value(overideprogtype)
                                value(userfilepath)
                                value(fileextension)
                                value(additionalsubdir)
                                value(converttohtml)
                                value(customernamerange)
                                value(getincludes)
                                value(getdictstructures)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.

  DATA: itemplines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: localfilenamewithpath TYPE string.
  DATA: localfilenameonly TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: objectname TYPE string.
  DATA: castclassname TYPE program.
  DATA: completesavepath TYPE string.

* Build up attribute comments
  APPEND '**************************************************************************' TO ilines.
  APPEND '*   Class attributes.                                                    *' TO ilines.
  APPEND '**************************************************************************' TO ilines.
  CASE walocclass-exposure.
    WHEN 0.
      APPEND `Instantiation: Private` TO ilines.
    WHEN 1.
      APPEND `Instantiation: Protected` TO ilines.
    WHEN 2.
      APPEND `Instantiation: Public` TO ilines.
  ENDCASE.
  CONCATENATE `Message class: ` walocclass-msg_id INTO ilines.
  APPEND ilines.
  CASE walocclass-state.
    WHEN 0.
      APPEND `State: Only Modelled` TO ilines.
    WHEN 1.
      APPEND `State: Implemented` TO ilines.
  ENDCASE.
  CONCATENATE `Final Indicator: ` walocclass-clsfinal INTO ilines.
  APPEND ilines.
  CONCATENATE `R/3 Release: ` walocclass-r3release INTO ilines.
  APPEND ilines.
  CLEAR ilines.
  APPEND ilines.

  castclassname = walocclass-publicclasskey.
  READ REPORT castclassname INTO itemplines.
  IF sy-subrc = 0.
    PERFORM reformatclasscode USING itemplines[].

    APPEND '**************************************************************************' TO ilines.
    APPEND '*   Public section of class.                                             *' TO ilines.
    APPEND '**************************************************************************' TO ilines.
    LOOP AT itemplines.
      APPEND itemplines TO ilines.
    ENDLOOP.
  ENDIF.

  castclassname = walocclass-privateclasskey.
  READ REPORT castclassname INTO itemplines.
  IF sy-subrc = 0.
    PERFORM reformatclasscode USING itemplines[].

    APPEND ilines.
    APPEND '**************************************************************************' TO ilines.
    APPEND '*   Private section of class.                                            *' TO ilines.
    APPEND '**************************************************************************' TO ilines.
    LOOP AT itemplines.
      APPEND itemplines TO ilines.
    ENDLOOP.
  ENDIF.

  castclassname = walocclass-protectedclasskey.
  READ REPORT castclassname INTO itemplines.
  IF sy-subrc = 0.
    PERFORM reformatclasscode USING itemplines[].

    APPEND ilines.
    APPEND '**************************************************************************' TO ilines.
    APPEND '*   Protected section of class.                                          *' TO ilines.
    APPEND '**************************************************************************' TO ilines.
    LOOP AT itemplines.
      APPEND itemplines TO ilines.
    ENDLOOP.
  ENDIF.

  castclassname = walocclass-typesclasskey.
  READ REPORT castclassname INTO itemplines.
  IF sy-subrc = 0.
    APPEND ilines.
    APPEND '**************************************************************************' TO ilines.
    APPEND '*   Types section of class.                                              *' TO ilines.
    APPEND '**************************************************************************' TO ilines.
    LOOP AT itemplines.
      APPEND itemplines TO ilines.
    ENDLOOP.
  ENDIF.

* Download text elements for this class
  IF NOT walocclass-itextelements[] IS INITIAL.
    PERFORM appendtextelements USING walocclass-itextelements[]
                                     ilines[].
  ENDIF.

* Download messages classes for this class.
  IF NOT walocclass-imessages[] IS INITIAL.
    PERFORM appendmessagestofile USING walocclass-imessages[]
                                       ilines[]
                                       space.
  ENDIF.

* Download exception texts for this class
  IF NOT walocclass-iconcepts[] IS INITIAL.
    PERFORM appendexceptiontexts USING walocclass-iconcepts[]
                                       ilines[].
  ENDIF.


  IF converttohtml IS INITIAL.
    APPEND '' TO ilines.
    APPEND '----------------------------------------------------------------------------------' TO ilines.
    PERFORM buildfootermessage USING ilines.
    APPEND ilines.
  ELSE.
    PERFORM convertclasstohtml USING ilines[]
                                    classname
                                    walocclass-descript
                                    overideprogtype
                                    fileextension
                                    customernamerange
                                    getdictstructures
                                    addbackground.
  ENDIF.

  IF functionname IS INITIAL.
    objectname = classname.
  ELSE.
    objectname = functionname.
  ENDIF.

  PERFORM buildfilename USING userfilepath
                              additionalsubdir
                              objectname
                              space
                              classname
                              fileextension
                              overideprogtype
                              savetoserver
                              slashseparator
                              localfilenamewithpath
                              localfilenameonly
                              newsubdirectory
                              completesavepath.

  IF savetoserver IS INITIAL.
    PERFORM savefiletopc USING ilines[]
                               localfilenamewithpath
                               localfilenameonly
                               space
                               space
                               displayprogressmessage.
  ELSE.
    PERFORM savefiletoserver USING ilines[]
                                   localfilenamewithpath
                                   localfilenameonly
                                   completesavepath
                                   displayprogressmessage
                                   locserverfilesystem.
  ENDIF.
ENDFORM.                                                                           "readClassAndDownload

*-------------------------------------------------------------------------------------------------------
*   readMethodAndDownload...
*-------------------------------------------------------------------------------------------------------
FORM readmethodanddownload USING walocmethod TYPE tmethod
                                value(methodname)
                                value(methodkey)
                                value(functionname)
                                value(overideprogtype)
                                value(userfilepath)
                                value(fileextension)
                                value(additionalsubdir)
                                value(converttohtml)
                                value(customernamerange)
                                value(getincludes)
                                value(getdictstructures)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: itemplines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: localfilenamewithpath TYPE string.
  DATA: localfilenameonly TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: objectname TYPE string.
  DATA: castmethodkey TYPE program.
  DATA: completesavepath TYPE string.

* Add the method scope to the downloaded file
  APPEND '**************************************************************************' TO ilines.
  APPEND '*   Method attributes.                                                   *' TO ilines.
  APPEND '**************************************************************************' TO ilines.
  CASE walocmethod-exposure.
    WHEN 0.
      APPEND `Instantiation: Private` TO ilines.
    WHEN 1.
      APPEND `Instantiation: Protected` TO ilines.
    WHEN 2.
      APPEND `Instantiation: Public` TO ilines.
  ENDCASE.
  APPEND '**************************************************************************' TO ilines.
  APPEND '' TO ilines.

  castmethodkey = walocmethod-methodkey.
  READ REPORT castmethodkey INTO itemplines.
  LOOP AT itemplines.
    APPEND itemplines TO ilines.
  ENDLOOP.

  IF converttohtml IS INITIAL.
    APPEND '' TO ilines.
    APPEND '----------------------------------------------------------------------------------' TO ilines.
    PERFORM buildfootermessage USING ilines.
    APPEND ilines.
  ELSE.
    PERFORM convertcodetohtml USING ilines[]
                                    methodname
                                    walocmethod-descript
                                    overideprogtype
                                    space
                                    space
                                    fileextension
                                    customernamerange
                                    getincludes
                                    getdictstructures
                                    addbackground.
  ENDIF.

  IF functionname IS INITIAL.
    objectname = methodname.
  ELSE.
    objectname = functionname.
  ENDIF.

  CASE walocmethod-exposure.
    WHEN 0.
*     Private
      CONCATENATE additionalsubdir slashseparator 'private_methods' INTO additionalsubdir.
    WHEN 1.
*     Protected
      CONCATENATE additionalsubdir slashseparator 'protected_methods' INTO additionalsubdir.
    WHEN 2.
*     Public
      CONCATENATE additionalsubdir slashseparator 'public_methods' INTO additionalsubdir.
  ENDCASE.

  PERFORM buildfilename USING userfilepath
                              additionalsubdir
                              objectname
                              space
                              methodname
                              fileextension
                              overideprogtype
                              savetoserver
                              slashseparator
                              localfilenamewithpath
                              localfilenameonly
                              newsubdirectory
                              completesavepath.

  IF savetoserver IS INITIAL.
    PERFORM savefiletopc USING ilines[]
                               localfilenamewithpath
                               localfilenameonly
                               space
                               space
                               displayprogressmessage.
  ELSE.
    PERFORM savefiletoserver USING ilines[]
                                   localfilenamewithpath
                                   localfilenameonly
                                   completesavepath
                                   displayprogressmessage
                                   locserverfilesystem.
  ENDIF.
ENDFORM.                                                                          "readMethodAndDownload

*-------------------------------------------------------------------------------------------------------
*   readXsltAndDownload...
*-------------------------------------------------------------------------------------------------------
FORM readxsltanddownload USING value(xsltname)
                                     xsltdescription
                               value(userfilepath)
                               value(fileextension)
                               value(converttohtml)
                               value(customernamerange)
                               value(slashseparator)
                               value(savetoserver)
                               value(subdir)
                               value(displayprogressmessage)
                               value(locserverfilesystem)
                               value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: ilocxsltsource TYPE o2pageline_table.
  DATA: waxsltattributes TYPE o2xsltattr.
  DATA: localfilenamewithpath TYPE string.
  DATA: localfilenameonly TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: objectname TYPE string.
  DATA: completesavepath TYPE string.

  cl_o2_api_xsltdesc=>load( EXPORTING p_xslt_desc = xsltname
                            IMPORTING p_source = ilocxsltsource
                                      p_attributes = waxsltattributes
                            EXCEPTIONS not_existing = 1
                                       permission_failure = 2
                                       error_occured = 3
                                       version_not_found = 4 ).

  IF sy-subrc = 0.
    xsltdescription = waxsltattributes-descript.

    APPEND LINES OF ilocxsltsource TO ilines.

    IF converttohtml IS INITIAL.
      APPEND '' TO ilines.
      APPEND '----------------------------------------------------------------------------------' TO ilines.
      PERFORM buildfootermessage USING ilines.
      APPEND ilines.
    ELSE.
      PERFORM convertcodetohtml USING ilines[]
                                      xsltname
                                      waxsltattributes-descript
                                      space
                                      space
                                      space
                                      fileextension
                                      customernamerange
                                      space
                                      space
                                      addbackground.
    ENDIF.

    PERFORM buildfilename USING userfilepath
                                subdir
                                xsltname
                                space
                                xsltname
                                fileextension
                                is_transformation
                                savetoserver
                                slashseparator
                                localfilenamewithpath
                                localfilenameonly
                                newsubdirectory
                                completesavepath.

    IF savetoserver IS INITIAL.
      PERFORM savefiletopc USING ilines[]
                                 localfilenamewithpath
                                 localfilenameonly
                                 space
                                 space
                                 displayprogressmessage.
    ELSE.
      PERFORM savefiletoserver USING ilines[]
                                     localfilenamewithpath
                                     localfilenameonly
                                     completesavepath
                                     displayprogressmessage
                                     locserverfilesystem.
    ENDIF.
  ENDIF.
ENDFORM.                                                                         "readXSLTAndDownload

*-------------------------------------------------------------------------------------------------------
*   readFunctionAndDownload...
*-------------------------------------------------------------------------------------------------------
FORM readfunctionanddownload USING iloctextelements LIKE dumitexttab[]
                                   ilocselectiontexts LIKE dumitexttab[]
                                   ilocmessages LIKE imessages[]
                                   value(functionname)
                                   value(functioninternalname)
                                   value(shorttext)
                                   value(userfilepath)
                                   value(fileextension)
                                   value(subdir)
                                   value(converttohtml)
                                   value(functiondocumentationexists)
                                   value(customernamerange)
                                   value(getincludes)
                                   value(getdictstructures)
                                   value(slashseparator)
                                   value(savetoserver)
                                   value(displayprogressmessage)
                                   value(locserverfilesystem)
                                   value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: localfilenamewithpath TYPE string.
  DATA: localfilenameonly TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: completesavepath TYPE string.

  READ REPORT functioninternalname INTO ilines.

* If we found any text elements for this function then we ought to append them to the main include.
  IF NOT iloctextelements[] IS INITIAL.
    PERFORM appendtextelements USING iloctextelements[]
                                     ilines[].
  ENDIF.

* If we found any message classes for this function then we ought to append them to the main include.
  IF NOT ilocmessages[] IS INITIAL.
    PERFORM appendmessagestofile USING ilocmessages[]
                                       ilines[]
                                       space.
  ENDIF.

  IF converttohtml IS INITIAL.
    APPEND '' TO ilines.
    APPEND '----------------------------------------------------------------------------------' TO ilines.
    PERFORM buildfootermessage USING ilines.
    APPEND ilines.
  ELSE.
    PERFORM convertfunctiontohtml USING ilines[]
                                        functionname
                                        shorttext
                                        is_function
                                        functiondocumentationexists
                                        true
                                        fileextension
                                        customernamerange
                                        getincludes
                                        getdictstructures
                                        addbackground.
  ENDIF.

  PERFORM buildfilename USING userfilepath
                              subdir
                              functionname
                              space
                              space
                              fileextension
                              is_function
                              savetoserver
                              slashseparator
                              localfilenamewithpath
                              localfilenameonly
                              newsubdirectory
                              completesavepath.

  IF savetoserver IS INITIAL.
    PERFORM savefiletopc USING ilines[]
                               localfilenamewithpath
                               localfilenameonly
                               space
                               space
                               displayprogressmessage.
  ELSE.
    PERFORM savefiletoserver USING ilines[]
                                   localfilenamewithpath
                                   localfilenameonly
                                   completesavepath
                                   displayprogressmessage
                                   locserverfilesystem.
  ENDIF.
ENDFORM.                                                                        "readFunctionAndDownload

*-------------------------------------------------------------------------------------------------------
*  buildFilename...
*-------------------------------------------------------------------------------------------------------
FORM buildfilename USING value(userpath)
                         value(additionalsubdirectory)
                         value(objectname)
                         value(mainfunctionno)
                         value(includename)
                         value(fileextension)
                         value(downloadtype)
                         value(downloadtoserver)
                         value(slashseparator)
                               newfilenamewithpath
                               newfilenameonly
                               newsubdirectory
                               completepath.

* If we are running on a non UNIX environment we will need to remove forward slashes from the additional path.
  IF downloadtoserver IS INITIAL.
    IF frontendopsystem = non_unix.
      IF NOT additionalsubdirectory IS INITIAL.
        TRANSLATE additionalsubdirectory USING '/_'.
        IF additionalsubdirectory+0(1) = '_'.
          SHIFT additionalsubdirectory LEFT BY 1 PLACES.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    IF serveropsystem = non_unix.
      IF NOT additionalsubdirectory IS INITIAL.
        TRANSLATE additionalsubdirectory USING '/_'.
        IF additionalsubdirectory+0(1) = '_'.
          SHIFT additionalsubdirectory LEFT BY 1 PLACES.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  CASE downloadtype.
*   Programs
    WHEN is_program.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator objectname period fileextension INTO newfilenamewithpath.
        CONCATENATE userpath slashseparator INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator objectname period fileextension INTO newfilenamewithpath.
        CONCATENATE userpath slashseparator additionalsubdirectory INTO completepath.
      ENDIF.

*   Function Modules
    WHEN is_function.
      IF additionalsubdirectory IS INITIAL.
        FIND 'top' IN includename IGNORING CASE.
        IF sy-subrc = 0.
          CONCATENATE userpath slashseparator objectname
                               slashseparator 'Global-' objectname
                               period fileextension
                               INTO newfilenamewithpath.
        ELSE.
          IF includename CS mainfunctionno AND NOT mainfunctionno IS INITIAL.
            CONCATENATE userpath slashseparator objectname
                                 slashseparator objectname
                                 period fileextension
                                 INTO newfilenamewithpath.
          ELSE.
            CONCATENATE userpath slashseparator objectname
                                 slashseparator objectname
                                 period fileextension
                                 INTO newfilenamewithpath.
          ENDIF.
        ENDIF.
        newsubdirectory = objectname.
        CONCATENATE userpath
                    slashseparator
                    newsubdirectory
                    slashseparator INTO completepath.
      ELSE.
        FIND 'top' IN includename IGNORING CASE.
        IF sy-subrc = 0.
          CONCATENATE userpath slashseparator additionalsubdirectory
                               slashseparator objectname
                               slashseparator 'Global-' objectname
                               period fileextension
                               INTO newfilenamewithpath.
        ELSE.
          IF includename CS mainfunctionno AND NOT mainfunctionno IS INITIAL.
            CONCATENATE userpath slashseparator additionalsubdirectory
                                 slashseparator objectname
                                 slashseparator objectname
                                 period fileextension
                                 INTO newfilenamewithpath.
          ELSE.
            CONCATENATE userpath slashseparator additionalsubdirectory
                                 slashseparator objectname
                                 slashseparator objectname
                                 period fileextension
                                 INTO newfilenamewithpath.
          ENDIF.
        ENDIF.
        CONCATENATE additionalsubdirectory slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO completepath.
      ENDIF.

*   Table definition
    WHEN is_table.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator 'dictionary'   " slashSeparator objectName
                             slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator 'dictionary' INTO newsubdirectory.
        CONCATENATE userpath slashseparator 'dictionary' INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator 'dictionary'   " slashSeparator objectName
                             slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'dictionary' INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'dictionary' INTO completepath.
      ENDIF.

*   Table definition
    WHEN is_transformation.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator 'Transformations'   " slashSeparator objectName
                             slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator 'Transformations' INTO newsubdirectory.
        CONCATENATE userpath slashseparator 'Transformations' INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator 'Transformations'   " slashSeparator objectName
                             slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'Transformations' INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'Transformations' INTO completepath.
      ENDIF.

*   Program & Function documentation
    WHEN is_documentation.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator objectname
                             slashseparator 'Docs-'
                             objectname period
                             fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator objectname INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator objectname
                             slashseparator 'Docs-'
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO completepath.
      ENDIF.

*   Screens
    WHEN is_screen.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator 'Screens'
                             slashseparator 'screen_'
                             objectname period
                             fileextension INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator 'screens' INTO newsubdirectory.
        CONCATENATE userpath slashseparator 'screens' INTO completepath.

      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator 'Screens'
                             slashseparator 'screen_'
                             objectname period
                             fileextension INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'screens' INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'screens' INTO completepath.
      ENDIF.

*   GUI title
    WHEN is_guititle.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator 'Screens'
                             slashseparator 'gui_title_'
                             objectname period
                             fileextension INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator 'screens' INTO newsubdirectory.
        CONCATENATE userpath slashseparator 'screens' INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator 'Screens'
                             slashseparator 'gui_title_'
                             objectname period
                             fileextension INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'Screens' INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator 'Screens' INTO completepath.
      ENDIF.

*   Message Class
    WHEN is_messageclass.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator objectname
                             slashseparator 'Message class-'
                             objectname period
                             fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator objectname INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator objectname
                             slashseparator 'Message class-'
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO completepath.
      ENDIF.

*   Class definition
    WHEN is_class.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator objectname
                             slashseparator 'Class-'
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator objectname INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator objectname
                             slashseparator 'Class-'
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory slashseparator objectname INTO completepath.
      ENDIF.

*   Class definition
    WHEN is_method.
      IF additionalsubdirectory IS INITIAL.
        CONCATENATE userpath slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

        CONCATENATE userpath slashseparator objectname INTO newsubdirectory.
        CONCATENATE userpath slashseparator objectname INTO completepath.
      ELSE.
        CONCATENATE userpath slashseparator additionalsubdirectory
                             slashseparator
                             objectname period fileextension
                             INTO newfilenamewithpath.

*        concatenate userPath slashSeparator additionalSubDirectory slashSeparator objectName into newSubDirectory.
        CONCATENATE userpath slashseparator additionalsubdirectory INTO completepath.
      ENDIF.
  ENDCASE.

  TRANSLATE completepath TO LOWER CASE.
  CONCATENATE objectname period fileextension INTO newfilenameonly.
  TRANSLATE newfilenameonly TO LOWER CASE.
  TRANSLATE newfilenamewithpath TO LOWER CASE.
  TRANSLATE newsubdirectory TO LOWER CASE.

* If we are running on a non UNIX environment we will need to remove incorrect characters from the filename.
  IF downloadtoserver IS INITIAL.
    IF frontendopsystem = non_unix.
      TRANSLATE newfilenameonly USING '/_'.
      TRANSLATE newfilenamewithpath USING '/_'.
      TRANSLATE newfilenameonly USING '< '.
      TRANSLATE newfilenamewithpath USING '< '.
      TRANSLATE newfilenameonly USING '> '.
      TRANSLATE newfilenamewithpath USING '> '.
      TRANSLATE newfilenameonly USING '? '.
      TRANSLATE newfilenamewithpath USING '? '.
      TRANSLATE newfilenameonly USING '| '.
      TRANSLATE newfilenamewithpath USING '| '.
      CONDENSE newfilenameonly NO-GAPS.
      CONDENSE newfilenamewithpath NO-GAPS.
    ENDIF.
  ELSE.
    IF serveropsystem = non_unix.
      TRANSLATE newfilenameonly USING '/_'.
      TRANSLATE newfilenamewithpath USING '/_'.
      TRANSLATE newfilenameonly USING '< '.
      TRANSLATE newfilenamewithpath USING '< '.
      TRANSLATE newfilenameonly USING '> '.
      TRANSLATE newfilenamewithpath USING '> '.
      TRANSLATE newfilenameonly USING '? '.
      TRANSLATE newfilenamewithpath USING '? '.
      TRANSLATE newfilenameonly USING '| '.
      TRANSLATE newfilenamewithpath USING '| '.
      CONDENSE newfilenameonly NO-GAPS.
      CONDENSE newfilenamewithpath NO-GAPS.
    ENDIF.
  ENDIF.
ENDFORM.                                                                                 "buildFilename

*-------------------------------------------------------------------------------------------------------
*  saveFileToPc...    write an internal table to a file on the local PC
*-------------------------------------------------------------------------------------------------------
FORM savefiletopc USING idownload TYPE STANDARD TABLE
                        value(filenamewithpath)
                        value(filename)
                        value(writefieldseparator)
                        value(truncatetrailingblanks)
                        value(displayprogressmessage).

  DATA: statusmessage TYPE string.
  DATA: objfile TYPE REF TO cl_gui_frontend_services.
  DATA: strsubrc TYPE string.

  IF NOT displayprogressmessage IS INITIAL.
    CONCATENATE `Downloading: ` filename INTO statusmessage.
    PERFORM displaystatus USING statusmessage 0.
  ENDIF.

  CREATE OBJECT objfile.
  objfile->gui_download( EXPORTING filename = filenamewithpath
                                    filetype = 'ASC'
                                    write_field_separator = writefieldseparator
                                    trunc_trailing_blanks = truncatetrailingblanks
                           CHANGING data_tab = idownload[]
                         EXCEPTIONS file_write_error        = 1
                                    no_batch                = 2
                                    gui_refuse_filetransfer = 3
                                    invalid_type            = 4
                                    no_authority            = 5
                                    unknown_error           = 6
                                    header_not_allowed      = 7
                                    separator_not_allowed   = 8
                                    filesize_not_allowed    = 9
                                    header_too_long         = 10
                                    dp_error_create         = 11
                                    dp_error_send           = 12
                                    dp_error_write          = 13
                                    unknown_dp_error        = 14
                                    access_denied           = 15
                                    dp_out_of_memory        = 16
                                    disk_full               = 17
                                    dp_timeout              = 18
                                    file_not_found          = 19
                                    dataprovider_exception  = 20
                                    control_flush_error     = 21
                                    not_supported_by_gui    = 22
                                    error_no_gui            = 23 ).

  IF sy-subrc <> 0.
    strsubrc = sy-subrc.
    CONCATENATE `File save error: ` filename ` sy-subrc: ` strsubrc INTO statusmessage.
    PERFORM displaystatus USING statusmessage 3.
  ENDIF.
ENDFORM.                                                                                                  "saveFileToPc

*----------------------------------------------------------------------------------------------------------------------
*  saveFileToServer...    write an internal table to a file on the SAP server
*----------------------------------------------------------------------------------------------------------------------
FORM savefiletoserver USING idownload TYPE STANDARD TABLE
                            value(filenamewithpath)
                            value(filename)
                            value(path)
                            value(displayprogressmessage)
                             value(locserverfilesystem).

  DATA: wadownload TYPE string.
  DATA: statusmessage TYPE string.
  DATA: pathexists TYPE flag.

  IF NOT displayprogressmessage IS INITIAL.
    CONCATENATE `Downloading: ` filename INTO statusmessage.
    PERFORM displaystatus USING statusmessage 0.
  ENDIF.

  READ TABLE iserverpaths WITH KEY table_line = path.
  IF sy-subrc <> 0.
    PERFORM checkpathexists USING path
                                  pathexists.

    IF pathexists = ''.
      PERFORM createserverdirectory USING path locserverfilesystem.
    ENDIF.
*   Add the paths we know exist as there is no point wasting time checking them again.
    APPEND path TO iserverpaths.
  ENDIF.

  OPEN DATASET filenamewithpath FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc = 0.
    LOOP AT idownload INTO wadownload.
      TRANSFER wadownload TO filenamewithpath.
      IF sy-subrc <> 0.
        MESSAGE e000(oo) WITH 'Error transferring data to file'.
      ENDIF.
    ENDLOOP.

    CLOSE DATASET filenamewithpath.
    IF sy-subrc <> 0.
      MESSAGE e000(oo) WITH 'Error closing file'.
    ENDIF.
  ELSE.
*   Unable to create a file
    MESSAGE e000(oo) WITH 'Error creating file on SAP server' 'check permissions'.
  ENDIF.
ENDFORM.                                                                                              "saveFileToServer

*----------------------------------------------------------------------------------------------------------------------
* checkPathExists...  Check a filepath exists on the application server.
*----------------------------------------------------------------------------------------------------------------------
FORM checkpathexists USING value(path)
                                 pathexists TYPE flag.

  DATA: castdirectory TYPE btctext80.

  castdirectory = path.

  CALL FUNCTION 'PFL_CHECK_DIRECTORY'
    EXPORTING
      directory                   = castdirectory
*     WRITE_CHECK                 = ' '
    EXCEPTIONS
      pfl_dir_not_exist           = 1
      pfl_permission_denied       = 2
      pfl_cant_build_dataset_name = 3
      pfl_file_not_exist          = 4
      OTHERS                      = 5.

  IF sy-subrc = 0.
    pathexists = 'X'.
  ELSE.
    pathexists = ''.
  ENDIF.
ENDFORM.                    "checkPathExists

*----------------------------------------------------------------------------------------------------------------------
* createServerDirectory...
*----------------------------------------------------------------------------------------------------------------------
FORM createserverdirectory USING value(path)
                                 value(locserverfilesystem).

  DATA: castserveropsys TYPE syopsys.

  castserveropsys = locserverfilesystem.

*  Parameters for remove command.
  DATA: param1 TYPE sxpgcolist-parameters.
*  Return status
  DATA: funcstatus TYPE extcmdexex-status.
*  Command line listing returned by the function
  DATA: iserveroutput TYPE STANDARD TABLE OF btcxpm.
  DATA: waserveroutput TYPE btcxpm.
*  Targetsystem type conversion variable.
  DATA: target TYPE rfcdisplay-rfchost.
* Operating system
  DATA: operatingsystem TYPE sxpgcolist-opsystem.
*  Head for split command.
  DATA: head TYPE string..
  DATA: tail TYPE string.

  param1 = path.
  target = sy-host.
  operatingsystem = locserverfilesystem.

  CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
    EXPORTING
      commandname                   = 'ZDTX_MKDIR'
      additional_parameters         = param1
      operatingsystem               = castserveropsys
      targetsystem                  = target
      stdout                        = 'X'
      stderr                        = 'X'
      terminationwait               = 'X'
    IMPORTING
      status                        = funcstatus
    TABLES
      exec_protocol                 = iserveroutput[]
    EXCEPTIONS
      no_permission                 = 1
      command_not_found             = 2
      parameters_too_long           = 3
      security_risk                 = 4
      wrong_check_call_interface    = 5
      program_start_error           = 6
      program_termination_error     = 7
      x_error                       = 8
      parameter_expected            = 9
      too_many_parameters           = 10
      illegal_command               = 11
      wrong_asynchronous_parameters = 12
      cant_enq_tbtco_entry          = 13
      jobcount_generation_error     = 14
      OTHERS                        = 15.

  IF sy-subrc = 0.
*   Although the function succeded did the external command actually work
    IF funcstatus = 'E'.
*     External command returned with an error
*     An error occurred creating the directory on the server
      MESSAGE e000(oo) WITH 'An error occurred creating a directory'.
    ENDIF.
  ELSE.
    CASE sy-subrc.
      WHEN 1.
*       No permissions to run the command
        MESSAGE e000(oo) WITH 'No permissions to run external command ZDTX_MKDIR'.
      WHEN 2.
*       External command not found
        MESSAGE e000(oo) WITH 'External comand ZDTX_MKDIR not found'.

      WHEN OTHERS.
*       Unable to create the directory
        MESSAGE e000(oo) WITH 'An error occurred creating a directory'
                              ', subrc:'
                              sy-subrc.
    ENDCASE.
  ENDIF.
ENDFORM.                                                                                         "createServerDirectory

*----------------------------------------------------------------------------------------------------------------------
* appendTextElements...
*----------------------------------------------------------------------------------------------------------------------
FORM appendtextelements USING iloctextelements LIKE dumitexttab[]
                              iloclines LIKE dumihtml[].

  FIELD-SYMBOLS: <watextelement> TYPE ttexttable.
  DATA: waline TYPE string.

  IF lines( iloctextelements ) > 0.
    APPEND '' TO iloclines.

    APPEND '*Text elements' TO iloclines.
    APPEND '*----------------------------------------------------------' TO  iloclines.
    LOOP AT iloctextelements ASSIGNING <watextelement>.
      CONCATENATE '*  ' <watextelement>-key <watextelement>-entry INTO waline SEPARATED BY space.
      APPEND waline TO iloclines.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                                            "appendTextElements

*----------------------------------------------------------------------------------------------------------------------
* appendGUITitles...
*----------------------------------------------------------------------------------------------------------------------
FORM appendguititles USING ilocguititles LIKE dumiguititle[]
                           iloclines LIKE dumihtml[].

  FIELD-SYMBOLS: <waguititle> TYPE tguititle.
  DATA: waline TYPE string.

  IF lines( ilocguititles ) > 0.
    APPEND '' TO iloclines.

    APPEND '*GUI Texts' TO iloclines.
    APPEND '*----------------------------------------------------------' TO  iloclines.
    LOOP AT ilocguititles ASSIGNING <waguititle>.
      CONCATENATE '*  ' <waguititle>-obj_code '-->' <waguititle>-text INTO waline SEPARATED BY space.
      APPEND waline TO iloclines.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                                               "appendGUITitles

*----------------------------------------------------------------------------------------------------------------------
* appendSelectionTexts...
*----------------------------------------------------------------------------------------------------------------------
FORM appendselectiontexts USING ilocselectiontexts LIKE dumitexttab[]
                                iloclines LIKE dumihtml[].

  FIELD-SYMBOLS: <waselectiontext> TYPE ttexttable.
  DATA: waline TYPE string.

  IF lines( ilocselectiontexts ) > 0.
    APPEND '' TO iloclines.
    APPEND '' TO iloclines.

    APPEND '*Selection texts' TO iloclines.
    APPEND '*----------------------------------------------------------' TO  iloclines.
    LOOP AT ilocselectiontexts ASSIGNING <waselectiontext>.
      CONCATENATE '*  ' <waselectiontext>-key <waselectiontext>-entry INTO waline SEPARATED BY space.
      APPEND waline TO iloclines.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                                          "appendSelectionTexts

*----------------------------------------------------------------------------------------------------------------------
* appendExceptionTexts...
*----------------------------------------------------------------------------------------------------------------------
FORM appendexceptiontexts USING iconcepts LIKE dumiconcepts[]
                                iloclines LIKE dumihtml[].

  FIELD-SYMBOLS: <waconcept> TYPE tconcept.
  DATA: waline TYPE string.
  DATA: concepttext TYPE sotr_txt.

  IF lines( iconcepts ) > 0.
    APPEND '' TO iloclines.

    APPEND '*Exception texts' TO iloclines.
    APPEND '*----------------------------------------------------------' TO  iloclines.
    LOOP AT iconcepts ASSIGNING <waconcept>.
*     Find the text for this concept
      CALL FUNCTION 'SOTR_GET_TEXT_KEY'
        EXPORTING
          concept                = <waconcept>-concept
          langu                  = pmlang
          search_in_second_langu = 'X'
*         second_langu           = 'DE'
        IMPORTING
          e_text                 = concepttext
        EXCEPTIONS
          no_entry_found         = 1
          parameter_error        = 2
          OTHERS                 = 3.

      IF sy-subrc = 0.
        CONCATENATE '*  ' <waconcept>-constname '-' concepttext  INTO waline SEPARATED BY space.
        APPEND waline TO iloclines.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                                                                                          "appendExceptionTexts

*----------------------------------------------------------------------------------------------------------------------
* downloadFunctionDocs...
*----------------------------------------------------------------------------------------------------------------------
FORM downloadfunctiondocs USING value(functionname)
                                value(functiondescription)
                                value(userfilepath)
                                value(fileextension)
                                value(converttohtml)
                                value(slashseparator)
                                value(savetoserver)
                                value(displayprogressmessage)
                                      subdir
                                      documentationdownloaded
                                value(locserverfilesystem)
                                value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: idocumentation TYPE STANDARD TABLE OF funct WITH HEADER LINE.
  DATA: iexceptions TYPE STANDARD TABLE OF rsexc WITH HEADER LINE.
  DATA: iexport TYPE STANDARD TABLE OF rsexp WITH HEADER LINE.
  DATA: iparameter TYPE STANDARD TABLE OF rsimp WITH HEADER LINE.
  DATA: itables TYPE STANDARD TABLE OF rstbl WITH HEADER LINE.
  DATA: iscriptlines TYPE STANDARD TABLE OF tline WITH HEADER LINE.
  DATA: htmlpagename TYPE string.
  DATA: newfilenamewithpath TYPE string.
  DATA: newfilenameonly TYPE string.
  DATA: object LIKE dokhl-object.
  DATA: stringlength TYPE i VALUE 0.
  DATA: newsubdirectory TYPE string.
  DATA: waline(255).
  DATA: completesavepath TYPE string.

  documentationdownloaded = false.
  object = functionname.

  CALL FUNCTION 'FUNCTION_IMPORT_DOKU'
    EXPORTING
      funcname           = functionname
    TABLES
      dokumentation      = idocumentation
      exception_list     = iexceptions
      export_parameter   = iexport
      import_parameter   = iparameter
      tables_parameter   = itables
    EXCEPTIONS
      error_message      = 1
      function_not_found = 2
      invalid_name       = 3
      OTHERS             = 4.

  CALL FUNCTION 'DOCU_GET'
    EXPORTING
      id                     = 'FU'
      langu                  = pmlang
      object                 = object
      typ                    = 'T'
      version_active_or_last = 'L'
    TABLES
      line                   = iscriptlines
    EXCEPTIONS
      no_docu_on_screen      = 1
      no_docu_self_def       = 2
      no_docu_temp           = 3
      ret_code               = 4
      OTHERS                 = 5.

  IF sy-subrc = 0 AND NOT ( iscriptlines[] IS INITIAL ).
    APPEND 'SHORT TEXT' TO ilines.
    CONCATENATE space functiondescription INTO functiondescription SEPARATED BY space.
    APPEND functiondescription TO ilines.
    APPEND space TO ilines.
    LOOP AT iscriptlines.
      MOVE iscriptlines-tdline TO ilines.
      CONCATENATE space ilines INTO ilines SEPARATED BY space.
      WHILE ilines CP '&*' OR ilines CP '*&'.
        REPLACE '&' INTO ilines WITH space.
        SHIFT ilines LEFT DELETING LEADING space.
      ENDWHILE.
      APPEND ilines.
    ENDLOOP.

    CLEAR ilines.
    IF NOT ( idocumentation[] IS INITIAL ).
      APPEND ilines.
      APPEND 'PARAMETER DOCUMENTATION' TO ilines.
      APPEND '-----------------------' TO ilines.
      APPEND ilines.

      DESCRIBE FIELD idocumentation-parameter LENGTH stringlength IN CHARACTER MODE.
      stringlength = stringlength + 3.
      LOOP AT idocumentation.
        MOVE idocumentation-parameter TO waline.
        MOVE idocumentation-stext TO waline+stringlength.
        APPEND waline TO ilines.
      ENDLOOP.
    ENDIF.

    CONCATENATE `Documentation - ` functionname INTO htmlpagename.

    IF converttohtml IS INITIAL.
      APPEND ilines.
      APPEND  '----------------------------------------------------------------------------------' TO ilines.
      APPEND ilines.
      PERFORM buildfootermessage USING ilines.
      APPEND ilines.
    ELSE.
      PERFORM convertcodetohtml USING ilines[]
                                      htmlpagename
                                      space
                                      is_documentation
                                      true
                                      space
                                      space
                                      space
                                      space
                                      space
                                      addbackground.
    ENDIF.

    PERFORM buildfilename USING userfilepath
                                subdir
                                functionname
                                space
                                space
                                fileextension
                                is_documentation
                                savetoserver
                                slashseparator
                                newfilenamewithpath
                                newfilenameonly
                                newsubdirectory
                                completesavepath.

    IF savetoserver IS INITIAL.
      PERFORM savefiletopc USING ilines[]
                                 newfilenamewithpath
                                 newfilenameonly
                                 space
                                 space
                                 displayprogressmessage.
    ELSE.
      PERFORM savefiletoserver USING ilines[]
                                     newfilenamewithpath
                                     newfilenameonly
                                     completesavepath
                                     displayprogressmessage
                                     locserverfilesystem.
    ENDIF.

    documentationdownloaded = true.
  ENDIF.
ENDFORM.                    "downloadFunctionDocs

*----------------------------------------------------------------------------------------------------------------------
* downloadClassDocs...
*----------------------------------------------------------------------------------------------------------------------
FORM downloadclassdocs USING value(classname) TYPE seoclsname
                             value(userfilepath)
                             value(fileextension)
                             value(converttohtml)
                             value(slashseparator)
                             value(savetoserver)
                             value(displayprogressmessage)
                                   subdir
                                   documentationdownloaded
                             value(locserverfilesystem)
                             value(addbackground) TYPE abap_bool.

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: idocumentation TYPE STANDARD TABLE OF funct WITH HEADER LINE.
  DATA: iexceptions TYPE STANDARD TABLE OF rsexc WITH HEADER LINE.
  DATA: iexport TYPE STANDARD TABLE OF rsexp WITH HEADER LINE.
  DATA: iparameter TYPE STANDARD TABLE OF rsimp WITH HEADER LINE.
  DATA: itables TYPE STANDARD TABLE OF rstbl WITH HEADER LINE.
  DATA: iscriptlines TYPE STANDARD TABLE OF tline WITH HEADER LINE.
  DATA: htmlpagename TYPE string.
  DATA: newfilenamewithpath TYPE string.
  DATA: newfilenameonly TYPE string.
  DATA: object LIKE dokhl-object.
  DATA: stringlength TYPE i VALUE 0.
  DATA: newsubdirectory TYPE string.
  DATA: waline(255).
  DATA: completesavepath TYPE string.

  documentationdownloaded = false.
  object = classname.

  CALL FUNCTION 'DOC_OBJECT_GET'
    EXPORTING
      class                  = 'CL'
      name                   = object
      language               = pmlang
*     short_text             = ' '
*     appendix               = ' '
*   importing
*     header                 = header
   TABLES
     itf_lines              = iscriptlines[]
   EXCEPTIONS
     object_not_found       = 1.

  IF sy-subrc = 0 AND NOT ( iscriptlines[] IS INITIAL ).
    LOOP AT iscriptlines.
      MOVE iscriptlines-tdline TO ilines.
      CONCATENATE space ilines INTO ilines SEPARATED BY space.
      WHILE ilines CP '&*' OR ilines CP '*&'.
        REPLACE '&' INTO ilines WITH space.
        SHIFT ilines LEFT DELETING LEADING space.
      ENDWHILE.
      APPEND ilines.
    ENDLOOP.

    CONCATENATE `Documentation - ` classname INTO htmlpagename.

    IF converttohtml IS INITIAL.
      APPEND ilines.
      APPEND  '----------------------------------------------------------------------------------' TO ilines.
      APPEND ilines.
      PERFORM buildfootermessage USING ilines.
      APPEND ilines.
    ELSE.
      PERFORM convertcodetohtml USING ilines[]
                                      htmlpagename
                                      space
                                      is_documentation
                                      true
                                      space
                                      space
                                      space
                                      space
                                      space
                                      addbackground.
    ENDIF.

    PERFORM buildfilename USING userfilepath
                                subdir
                                classname
                                space
                                space
                                fileextension
                                is_documentation
                                savetoserver
                                slashseparator
                                newfilenamewithpath
                                newfilenameonly
                                newsubdirectory
                                completesavepath.

    IF savetoserver IS INITIAL.
      PERFORM savefiletopc USING ilines[]
                                 newfilenamewithpath
                                 newfilenameonly
                                 space
                                 space
                                 displayprogressmessage.
    ELSE.
      PERFORM savefiletoserver USING ilines[]
                                     newfilenamewithpath
                                     newfilenameonly
                                     completesavepath
                                     displayprogressmessage
                                     locserverfilesystem.
    ENDIF.

    documentationdownloaded = true.
  ENDIF.
ENDFORM.                    "downloadClassDocs
*----------------------------------------------------------------------------------------------------------------------
*  downloadScreens...
*----------------------------------------------------------------------------------------------------------------------
FORM downloadscreens USING ilocscreenflow LIKE dumiscreen[]
                           value(programname)
                           value(userfilepath)
                           value(textfileextension)
                           value(subdir)
                           value(slashseparator)
                           value(savetoserver)
                           value(displayprogressmessage)
                           value(locserverfilesystem).


  TABLES: d020t.
  DATA: header LIKE d020s.
  DATA: ifields TYPE STANDARD TABLE OF d021s WITH HEADER LINE.
  DATA: iflowlogic TYPE STANDARD TABLE OF d022s WITH HEADER LINE.
  FIELD-SYMBOLS <wascreen> TYPE tscreenflow.
  DATA: wacharheader TYPE scr_chhead.
  DATA: iscreenchar TYPE STANDARD TABLE OF scr_chfld WITH HEADER LINE.
  DATA: ifieldschar TYPE STANDARD TABLE OF scr_chfld WITH HEADER LINE.
  DATA: stars TYPE string VALUE '****************************************************************'.
  DATA: comment1 TYPE string VALUE '*   This file was generated by Direct Download Enterprise.     *'.
  DATA: comment2 TYPE string VALUE '*   Please do not change it manually.                          *'.
  DATA: dynprotext TYPE string VALUE '%_DYNPRO'.
  DATA: headertext TYPE string VALUE '%_HEADER'.
  DATA: paramstext TYPE string VALUE '%_PARAMS'.
  DATA: descriptiontext TYPE string VALUE '%_DESCRIPTION'.
  DATA: fieldstext TYPE string VALUE '%_FIELDS'.
  DATA: flowlogictext TYPE string VALUE '%_FLOWLOGIC'.
  DATA: programlength TYPE string.
  DATA: newsubdirectory TYPE string.
  DATA: newfilenamewithpath TYPE string.
  DATA: newfilenameonly TYPE string.
  DATA: completesavepath TYPE string.

  LOOP AT ilocscreenflow ASSIGNING <wascreen>.
    CALL FUNCTION 'RS_IMPORT_DYNPRO'
      EXPORTING
        dylang = pmlang
        dyname = programname
        dynumb = <wascreen>-screen
      IMPORTING
        header = header
      TABLES
        ftab   = ifields
        pltab  = iflowlogic.

    CALL FUNCTION 'RS_SCRP_HEADER_RAW_TO_CHAR'
      EXPORTING
        header_int  = header
      IMPORTING
        header_char = wacharheader
      EXCEPTIONS
        OTHERS      = 1.

*   Add in the top comments for the file
    APPEND stars TO iscreenchar .
    APPEND comment1 TO iscreenchar.
    APPEND comment2 TO iscreenchar.
    APPEND stars TO iscreenchar.

*   Screen identification
    APPEND dynprotext TO iscreenchar.
    APPEND wacharheader-prog TO iscreenchar.
    APPEND wacharheader-dnum TO iscreenchar.
    APPEND sy-saprl TO iscreenchar.
    DESCRIBE FIELD d020t-prog LENGTH programlength IN CHARACTER MODE.
    CONCATENATE `                ` programlength INTO iscreenchar.
    APPEND iscreenchar.

*   Header
    APPEND headertext TO iscreenchar.
    APPEND wacharheader TO iscreenchar.

*   Description text
    APPEND descriptiontext TO iscreenchar.
    SELECT SINGLE dtxt FROM d020t INTO iscreenchar
                       WHERE prog = programname
                             AND dynr = <wascreen>-screen
                             AND lang = pmlang.
    APPEND iscreenchar.

*   Fieldlist text
    APPEND fieldstext TO iscreenchar.

    CALL FUNCTION 'RS_SCRP_FIELDS_RAW_TO_CHAR'
      TABLES
        fields_int  = ifields[]
        fields_char = ifieldschar[]
      EXCEPTIONS
        OTHERS      = 1.

    LOOP AT ifieldschar.
      MOVE-CORRESPONDING ifieldschar TO iscreenchar.
      APPEND iscreenchar.
    ENDLOOP.

*   Flowlogic text
    APPEND flowlogictext TO iscreenchar.
*   Flow logic.
    LOOP AT iflowlogic.
      APPEND iflowlogic TO iscreenchar.
    ENDLOOP.

    PERFORM buildfilename USING userfilepath
                                subdir
                                wacharheader-dnum
                                space
                                space
                                textfileextension
                                is_screen
                                savetoserver
                                slashseparator
                                newfilenamewithpath
                                newfilenameonly
                                newsubdirectory
                                completesavepath.

    IF savetoserver IS INITIAL.
*     Save the screen to the local computer
      PERFORM savefiletopc USING iscreenchar[]
                                 newfilenamewithpath
                                 newfilenameonly
                                 'X'
                                 'X'
                                 displayprogressmessage.
    ELSE.
*     Save the screen to the SAP server
      PERFORM savefiletoserver USING iscreenchar[]
                                     newfilenamewithpath
                                     newfilenameonly
                                     completesavepath
                                     displayprogressmessage
                                     locserverfilesystem.
    ENDIF.

    CLEAR header. CLEAR wacharheader.
    CLEAR iscreenchar[].
    CLEAR ifieldschar[].
    CLEAR ifields[].
    CLEAR iflowlogic[].
  ENDLOOP.
ENDFORM.                                                                                               "downloadScreens

*----------------------------------------------------------------------------------------------------------------------
*  downloadGUITitles..
*----------------------------------------------------------------------------------------------------------------------
FORM downloadguititles USING ilocguititles LIKE dumiguititle[]
                             value(userfilepath)
                             value(textfileextension)
                             value(subdir)
                             value(slashseparator)
                             value(savetoserver)
                             value(displayprogressmessage)
                             value(locserverfilesystem).

  DATA: ilines TYPE STANDARD TABLE OF string WITH HEADER LINE.
  FIELD-SYMBOLS: <waguititle> TYPE tguititle.
  DATA: newsubdirectory TYPE string.
  DATA: newfilenamewithpath TYPE string.
  DATA: newfilenameonly TYPE string.
  DATA: completesavepath TYPE string.

  LOOP AT ilocguititles ASSIGNING <waguititle>.
    APPEND <waguititle>-text TO ilines.

    PERFORM buildfilename USING userfilepath
                                subdir
                                <waguititle>-obj_code
                                space
                                space
                                textfileextension
                                is_guititle
                                savetoserver
                                slashseparator
                                newfilenamewithpath
                                newfilenameonly
                                newsubdirectory
                                completesavepath.

    IF savetoserver IS INITIAL.
      PERFORM savefiletopc USING ilines[]
                                 newfilenamewithpath
                                 newfilenameonly
                                 space
                                 space
                                 displayprogressmessage.
    ELSE.
      PERFORM savefiletoserver USING ilines[]
                                     newfilenamewithpath
                                     newfilenameonly
                                     completesavepath
                                     displayprogressmessage
                                     locserverfilesystem.
    ENDIF.

    CLEAR ilines[].
  ENDLOOP.
ENDFORM.                                                                                             "downloadGUITitles

*----------------------------------------------------------------------------------------------------------------------
*  downloadPrograms..
*----------------------------------------------------------------------------------------------------------------------
FORM downloadprograms USING ilocprogram LIKE iprograms[]
                            ilocfunctions LIKE ifunctions[]
                            ilocdictionaryfilename LIKE idictfilename[]
                            iloctabletypefilename LIKE itabletypefilename[]
                            value(userfilepath)
                            value(fileextension)
                            value(htmlfileextension)
                            value(textfileextension)
                            value(converttohtml)
                            value(customernamerange)
                            value(getincludes)
                            value(getdictstruct)
                            value(downloaddocumentation)
                            value(sorttablesasc)
                            value(slashseparator)
                            value(savetoserver)
                            value(displayprogressmessage)
                            value(locserverfilesystem)
                            value(addbackground) TYPE abap_bool.


  DATA: iprogfunctions TYPE STANDARD TABLE OF tfunction WITH HEADER LINE.
  FIELD-SYMBOLS: <waprogram> TYPE tprogram.
  FIELD-SYMBOLS: <wainclude> TYPE tinclude.
  DATA: iemptytextelements TYPE STANDARD TABLE OF ttexttable.
  DATA: iemptyselectiontexts TYPE STANDARD TABLE OF ttexttable.
  DATA: iemptymessages TYPE STANDARD TABLE OF tmessage.
  DATA: iemptyguititles TYPE STANDARD TABLE OF tguititle.
  DATA: locconverttohtml(1).
  DATA: locfileextension TYPE string.

  SORT ilocprogram ASCENDING BY progname.

  LOOP AT ilocprogram ASSIGNING <waprogram>.
*   if the program to download is this program then always download as text otherwise you will get a rubbish file
    IF <waprogram>-progname = sy-cprog.
      locconverttohtml = ''.
      locfileextension = textextension.
    ELSE.
      locconverttohtml = converttohtml.
      locfileextension = fileextension.
    ENDIF.

*   Download the main program
    PERFORM readincludeanddownload USING <waprogram>-itextelements[]
                                         <waprogram>-iselectiontexts[]
                                         <waprogram>-imessages[]
                                         <waprogram>-iguititle[]
                                         <waprogram>-progname
                                         space
                                         <waprogram>-programtitle
                                         is_program
                                         userfilepath
                                         locfileextension
                                         <waprogram>-progname
                                         locconverttohtml
                                         customernamerange
                                         getincludes
                                         getdictstruct
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.

*   Download screens.
    IF NOT <waprogram>-iscreenflow[] IS INITIAL.
      PERFORM downloadscreens USING <waprogram>-iscreenflow[]
                                    <waprogram>-progname
                                    userfilepath
                                    textfileextension
                                    <waprogram>-progname
                                    slashseparator
                                    savetoserver
                                    displayprogressmessage
                                    locserverfilesystem.
    ENDIF.

*   Download GUI titles
    IF NOT <waprogram>-iguititle[] IS INITIAL.
      PERFORM downloadguititles USING <waprogram>-iguititle
                                      userfilepath
                                      textfileextension
                                      <waprogram>-progname
                                      slashseparator
                                      savetoserver
                                      displayprogressmessage
                                      locserverfilesystem.
    ENDIF.

*   Download all other includes
    LOOP AT <waprogram>-iincludes ASSIGNING <wainclude>.
      PERFORM readincludeanddownload USING iemptytextelements[]
                                           iemptyselectiontexts[]
                                           iemptymessages[]
                                           iemptyguititles[]
                                           <wainclude>-includename
                                           space
                                           <wainclude>-includetitle
                                           is_program
                                           userfilepath
                                           fileextension
                                           <waprogram>-progname
                                           converttohtml
                                           customernamerange
                                           getincludes
                                           getdictstruct
                                           slashseparator
                                           savetoserver
                                           displayprogressmessage
                                           locserverfilesystem
                                           addbackground.

    ENDLOOP.

*   Download all dictionary structures
    IF NOT <waprogram>-idictstruct[] IS INITIAL.
      PERFORM downloadddstructures USING <waprogram>-idictstruct[]
                                         ilocdictionaryfilename[]
                                         userfilepath
                                         htmlfileextension
                                         <waprogram>-progname
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download all Table Types
    IF NOT <waprogram>-itabletypes[] IS INITIAL.
      PERFORM downloadddtabletypes USING <waprogram>-itabletypes[]
                                         iloctabletypefilename[]
                                         userfilepath
                                         htmlfileextension
                                         <waprogram>-progname
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download Transformations
    IF NOT <waprogram>-itransformations[] IS INITIAL.
      PERFORM downloadxslt USING <waprogram>-itransformations[]
                                 userfilepath
                                 fileextension
                                 htmlfileextension
                                 textfileextension
                                 converttohtml
                                 customernamespace
                                 slashseparatortouse
                                 savetoserver
                                 <waprogram>-progname
                                 displayprogressmessage
                                 serverfilesystem
                                 addbackground.
    ENDIF.

*   Download any functions used by these programs
    LOOP AT ilocfunctions INTO iprogfunctions WHERE programlinkname = <waprogram>-progname.
      APPEND iprogfunctions.
    ENDLOOP.

    IF NOT iprogfunctions[] IS INITIAL.
      PERFORM downloadfunctions USING iprogfunctions[]
                                      ilocdictionaryfilename[]
                                      itabletypefilename[]
                                      userfilepath
                                      fileextension
                                      <waprogram>-progname
                                      downloaddocumentation
                                      converttohtml
                                      customernamerange
                                      getincludes
                                      getdictstruct
                                      textfileextension
                                      htmlfileextension
                                      sorttablesasc
                                      slashseparator
                                      savetoserver
                                      displayprogressmessage
                                      locserverfilesystem
                                      addbackground.
      CLEAR iprogfunctions[].
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                              "downloadPrograms

*----------------------------------------------------------------------------------------------------------------------
*  downloadClasses..
*----------------------------------------------------------------------------------------------------------------------
FORM downloadclasses USING ilocclasses LIKE iclasses[]
                           ilocfunctions LIKE ifunctions[]
                           ilocdictionaryfilename LIKE idictfilename[]
                           iloctabletypefilename LIKE itabletypefilename[]
                           value(userfilepath)
                           value(fileextension)
                           value(htmlfileextension)
                           value(textfileextension)
                           value(converttohtml)
                           value(customernamerange)
                           value(getincludes)
                           value(getdictstruct)
                           value(downloaddocumentation)
                           value(sorttablesasc)
                           value(slashseparator)
                           value(savetoserver)
                           value(displayprogressmessage)
                           value(locserverfilesystem)
                           value(addbackground) TYPE abap_bool.


  DATA: iclassfunctions TYPE STANDARD TABLE OF tfunction WITH HEADER LINE.
  FIELD-SYMBOLS: <waclass> TYPE tclass.
  FIELD-SYMBOLS: <wamethod> TYPE tmethod.
  DATA: additionalsubdirectory TYPE string.
  DATA: classdocumentationexists TYPE abap_bool VALUE false.

  SORT ilocclasses ASCENDING BY clsname.

  LOOP AT ilocclasses ASSIGNING <waclass>.
*   Download the class
    PERFORM readclassanddownload USING <waclass>
                                        <waclass>-clsname
                                        space
                                        is_class
                                        userfilepath
                                        fileextension
                                        space
                                        converttohtml
                                        customernamerange
                                        getincludes
                                        getdictstruct
                                        slashseparator
                                        savetoserver
                                        displayprogressmessage
                                        locserverfilesystem
                                        addbackground.


*   Download all of the methods
    LOOP AT <waclass>-imethods ASSIGNING <wamethod>.
      additionalsubdirectory = <waclass>-clsname.
      PERFORM readmethodanddownload USING <wamethod>
                                          <wamethod>-cmpname
                                          <wamethod>-methodkey
                                          space
                                          is_method
                                          userfilepath
                                          fileextension
                                          additionalsubdirectory
                                          converttohtml
                                          customernamerange
                                          getincludes
                                          getdictstruct
                                          slashseparator
                                          savetoserver
                                          displayprogressmessage
                                          locserverfilesystem
                                          addbackground.

    ENDLOOP.

*   Download all dictionary structures
    IF NOT <waclass>-idictstruct[] IS INITIAL.
      PERFORM downloadddstructures USING <waclass>-idictstruct[]
                                         ilocdictionaryfilename[]
                                         userfilepath
                                         htmlfileextension
                                         <waclass>-clsname
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download all Table Types
    IF NOT <waclass>-itabletypes[] IS INITIAL.
      PERFORM downloadddtabletypes USING <waclass>-itabletypes[]
                                         iloctabletypefilename[]
                                         userfilepath
                                         htmlfileextension
                                         <waclass>-clsname
                                         sorttablesasc
                                         slashseparator
                                         savetoserver
                                         displayprogressmessage
                                         locserverfilesystem
                                         addbackground.
    ENDIF.

*   Download Transformations
    IF NOT <waclass>-itransformations[] IS INITIAL.
      PERFORM downloadxslt USING <waclass>-itransformations[]
                                 userfilepath
                                 fileextension
                                 htmlfileextension
                                 textfileextension
                                 converttohtml
                                 customernamespace
                                 slashseparatortouse
                                 savetoserver
                                 <waclass>-clsname
                                 displayprogressmessage
                                 serverfilesystem
                                 addbackground.
    ENDIF.

*   Download any functions used by these programs
    LOOP AT ilocfunctions INTO iclassfunctions WHERE programlinkname = <waclass>-clsname.
      APPEND iclassfunctions.
    ENDLOOP.

    IF NOT iclassfunctions[] IS INITIAL.
      PERFORM downloadfunctions USING iclassfunctions[]
                                      ilocdictionaryfilename[]
                                      iloctabletypefilename[]
                                      userfilepath
                                      fileextension
                                      <waclass>-clsname
                                      downloaddocumentation
                                      converttohtml
                                      customernamerange
                                      getincludes
                                      getdictstruct
                                      textfileextension
                                      htmlfileextension
                                      sorttablesasc
                                      slashseparator
                                      savetoserver
                                      displayprogressmessage
                                      locserverfilesystem
                                      addbackground.
      CLEAR iclassfunctions[].
    ENDIF.

    IF downloaddocumentation = true.
      PERFORM downloadclassdocs USING <waclass>-clsname
                                       userfilepath
                                       fileextension
                                       converttohtml
                                       slashseparator
                                       savetoserver
                                       displayprogressmessage
                                      '' "subdirectory
                                       classdocumentationexists
                                       locserverfilesystem
                                       addbackground.
    ENDIF.
  ENDLOOP.
ENDFORM.                                                                                               "downloadClasses

*-------------------------------------------------------------------------------------------------------
*   downloadXslt...
*-------------------------------------------------------------------------------------------------------
FORM downloadxslt USING iloctransformation LIKE itransformations[]
                            value(userfilepath)
                            value(fileextension)
                            value(htmlfileextension)
                            value(textfileextension)
                            value(converttohtml)
                            value(customernamerange)
                            value(slashseparator)
                            value(savetoserver)
                            value(subdir)
                            value(displayprogressmessage)
                            value(locserverfilesystem)
                            value(addbackground) TYPE abap_bool.

  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.

  SORT iloctransformation ASCENDING.

  LOOP AT iloctransformation ASSIGNING <watransformation>.
*   Download the main program
    PERFORM readxsltanddownload USING <watransformation>-xsltname
                                      <watransformation>-xsltdesc
                                      userfilepath
                                      fileextension
                                      converttohtml
                                      customernamerange
                                      slashseparator
                                      savetoserver
                                      subdir
                                      displayprogressmessage
                                      locserverfilesystem
                                      addbackground.
  ENDLOOP.
ENDFORM.                                                                                              "downloadXSLT

*----------------------------------------------------------------------------------------------------------------------
*  reFormatClassCode...   Expand a classes public, private and protected section from the 72 characters that the class
*                         builder sets it to back to the wide editor mode
*----------------------------------------------------------------------------------------------------------------------
FORM reformatclasscode USING itemplines LIKE dumihtml[].

  FIELD-SYMBOLS: <waline> TYPE string.
  DATA: newline TYPE string.
  DATA: inewtable TYPE STANDARD TABLE OF string.
  DATA: foundone TYPE abap_bool VALUE false.

  LOOP AT itemplines ASSIGNING <waline>.
    IF NOT <waline> IS INITIAL.
      IF foundone = false.
        FIND 'data' IN <waline> RESPECTING CASE.
        IF sy-subrc = 0.
          foundone = true.
        ENDIF.

        FIND 'constants' IN <waline> RESPECTING CASE.
        IF sy-subrc = 0.
          foundone = true.
        ENDIF.

        IF foundone = true.
          newline = <waline>.

          IF ( newline CS '.' OR newline CS '*' ).
            REPLACE '!' IN <waline> WITH ''.
            APPEND newline TO inewtable.
            CLEAR newline.
            foundone = false.
          ENDIF.
        ELSE.
          REPLACE '!' IN <waline> WITH ''.
          APPEND <waline> TO inewtable.
        ENDIF.
      ELSE.
        CONCATENATE newline <waline> INTO newline SEPARATED BY space.
        IF ( newline CS '.' OR newline CS '*' ).
          APPEND newline TO inewtable.
          CLEAR newline.
          foundone = false.
        ENDIF.
      ENDIF.
    ELSE.
      REPLACE '!' IN <waline> WITH ''.
      APPEND <waline> TO inewtable[].
    ENDIF.
  ENDLOOP.

  itemplines[] = inewtable[].
ENDFORM.                                                                             "reFormatClassCode

***********************************************************************************************************************
**********************************************HTML ROUTINES************************************************************
***********************************************************************************************************************

*----------------------------------------------------------------------------------------------------------------------
*  convertDDToHTML...   Convert text description to HTML
*----------------------------------------------------------------------------------------------------------------------
FORM convertddtohtml USING ilocdictstructure LIKE dumidictstructure[]
                           ilochtml LIKE dumihtml[]
                           value(tablename)
                           value(tabletitle)
                           value(sorttablesasc)
                           value(addbackground) TYPE abap_bool..

  DATA: icolumncaptions TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: wadictionary TYPE tdicttablestructure.
  DATA: wahtml TYPE string.
  DATA: title TYPE string.
  FIELD-SYMBOLS: <ilocdictstructure> TYPE tdicttablestructure.
* Holds one cell from the internal table
  FIELD-SYMBOLS: <fsfield>.
* The value of one cell form the internal table
  DATA: wtextcell TYPE string.
  DATA: rowcounter(3).
* The base type of the field we are reading
  DATA: wfieldbasetype.

  PERFORM buildddcolumnheaders USING icolumncaptions[].

* Add a html header to the table
  CONCATENATE 'Dictionary object-' tablename INTO title SEPARATED BY space.
  PERFORM addhtmlheader USING ilochtml[]
                              title
                              addbackground
                              ss_table.

  APPEND `<body>` TO ilochtml.
  APPEND `  <table class="outerTable">` TO ilochtml.
  APPEND `    <tr>` TO ilochtml.
  CONCATENATE `      <td><h2>Table: ` tablename '</h2>' INTO wahtml.
  APPEND wahtml TO ilochtml.
  CONCATENATE `  <h3>Description: ` tabletitle '</h3></td>' INTO wahtml.
  APPEND wahtml TO ilochtml.
  APPEND `    </tr>` TO ilochtml.

  APPEND `    <tr>` TO ilochtml.
  APPEND `      <td><!--This is where our main table begins  -->` TO ilochtml.
  APPEND `<table class="innerTable">` TO ilochtml.

* Do we need to sort the fields into alphabetical order
  IF NOT sorttablesasc IS INITIAL.
    SORT ilocdictstructure ASCENDING BY fieldname.
  ENDIF.

* This is where the header fields are defined
  APPEND `<tr>` TO ilochtml.
  LOOP AT icolumncaptions.
    CONCATENATE `  <th>` icolumncaptions `</th>` INTO wahtml.
    APPEND wahtml TO ilochtml.
  ENDLOOP.
  APPEND `</tr>` TO ilochtml.

* Add the table cells here
  LOOP AT ilocdictstructure ASSIGNING <ilocdictstructure>.
    APPEND `<tr class="cell">` TO ilochtml.
    rowcounter = rowcounter + 1.
    CONCATENATE `  <td>` rowcounter `</td>` INTO wahtml.
    APPEND wahtml TO ilochtml.

    DO.
*     Assign each field in the table to the field symbol
      ASSIGN COMPONENT sy-index OF STRUCTURE <ilocdictstructure> TO <fsfield>.
      IF sy-subrc = 0.
        DESCRIBE FIELD <fsfield> TYPE wfieldbasetype.
        IF wfieldbasetype <> 'h'.
          MOVE <fsfield> TO wtextcell.
          wahtml = `  <td>`.

*         Add the caption name
          IF wtextcell IS INITIAL.
            CONCATENATE wahtml '&nbsp;' '</td>' INTO wahtml.
          ELSE.
            CONCATENATE wahtml wtextcell '</td>' INTO wahtml.
          ENDIF.

          APPEND wahtml TO ilochtml.
          CLEAR wahtml.
        ENDIF.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

    APPEND `</tr>` TO ilochtml.
  ENDLOOP.

  APPEND `      </table>` TO ilochtml.
  APPEND `     </td>` TO ilochtml.
  APPEND `   </tr>` TO ilochtml.
  APPEND '<br/>' TO ilochtml.

* Add in any domain entries
  PERFORM adddomaintohtml USING ilocdictstructure[]
                                ilochtml[].

* Add a html footer to the table
  PERFORM addhtmlfooter USING ilochtml[].
ENDFORM.                                                                                               "convertDDToHTML

*----------------------------------------------------------------------------------------------------------------------
*  addDomaintoHTML...   Add domain vlaues into the HTML
*----------------------------------------------------------------------------------------------------------------------
FORM adddomaintohtml USING ilocdictstructure LIKE dumidictstructure[]
                           ilochtml LIKE dumihtml[].

  DATA: icolumncaptions TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: wadictionary TYPE tdicttablestructure.
  DATA: wahtml TYPE string.
  DATA: title TYPE string.
  FIELD-SYMBOLS: <ilocdictstructure> TYPE tdicttablestructure.
  DATA: idomstructure TYPE STANDARD TABLE OF tdomainstructure WITH HEADER LINE.
* Holds one cell from the internal table
  FIELD-SYMBOLS: <fsfield>.
* The value of one cell form the internal table
  DATA: wtextcell TYPE string.
  DATA: rowcounter(3).
* The base type of the field we are reading
  DATA: wfieldbasetype.
  DATA: addedheader TYPE flag VALUE ''.

  PERFORM builddomcolumnheaders USING icolumncaptions[].

* Add the table cells here
  LOOP AT ilocdictstructure ASSIGNING <ilocdictstructure>.
    LOOP AT <ilocdictstructure>-idomains INTO idomstructure.
*     OK, lets add the header since we know we have some domain texrt to add.
      IF addedheader = ''.
        APPEND `  <table class="outerTable">` TO ilochtml.
        APPEND `    <tr>` TO ilochtml.
        CONCATENATE `      <td><h2>Fixed Domain Values ` '</h2>' INTO wahtml.
        APPEND wahtml TO ilochtml.
        APPEND `    </tr>` TO ilochtml.

        APPEND `    <tr>` TO ilochtml.
        APPEND `      <td><!--This is where our main table begins  -->` TO ilochtml.
        APPEND `<table class="innerTable">` TO ilochtml.

*       This is where the header fields are defined
        APPEND `<tr>` TO ilochtml.
        LOOP AT icolumncaptions.
          CONCATENATE `  <th>` icolumncaptions `</th>` INTO wahtml.
          APPEND wahtml TO ilochtml.
        ENDLOOP.
        APPEND `</tr>` TO ilochtml.
        addedheader = 'X'.
      ENDIF.

      APPEND `<tr class="cell">` TO ilochtml.
      DO.
*       Assign each field in the table to the field symbol
        ASSIGN COMPONENT sy-index OF STRUCTURE idomstructure TO <fsfield>.
        IF sy-subrc = 0.
          DESCRIBE FIELD <fsfield> TYPE wfieldbasetype.
          IF wfieldbasetype <> 'h'.
            MOVE <fsfield> TO wtextcell.
            wahtml = `  <td>`.

*           Add the caption name
            IF wtextcell IS INITIAL.
              CONCATENATE wahtml '&nbsp;' '</td>' INTO wahtml.
            ELSE.
              CONCATENATE wahtml wtextcell '</td>' INTO wahtml.
            ENDIF.

            APPEND wahtml TO ilochtml.
            CLEAR wahtml.
          ENDIF.
        ELSE.
          EXIT.
        ENDIF.
      ENDDO.

      APPEND `</tr>` TO ilochtml.
    ENDLOOP.
  ENDLOOP.

  IF addedheader = 'X'.
    APPEND `      </table>` TO ilochtml.
    APPEND `     </td>` TO ilochtml.
    APPEND `   </tr>` TO ilochtml.
  ENDIF.
ENDFORM.                    "addDomaintoHTML
*----------------------------------------------------------------------------------------------------------------------
*  convertTableTypeToHtml
*----------------------------------------------------------------------------------------------------------------------
FORM converttabletypetohtml USING iloctabletypes LIKE itabletypes[]
                                  ilochtml LIKE dumihtml[]
                                  value(tablename)
                                  value(tabletitle)
                                  value(sorttablesasc)
                                  value(addbackground) TYPE abap_bool.

  DATA: icolumncaptions TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: wadictionary TYPE tdicttablestructure.
  DATA: wahtml TYPE string.
  DATA: title TYPE string.
  FIELD-SYMBOLS: <iloctabletype> LIKE LINE OF iloctabletypes.
* Holds one cell from the internal table
  FIELD-SYMBOLS: <fsfield>.
* The value of one cell form the internal table
  DATA: wtextcell TYPE string.
  DATA: rowcounter(3).

  PERFORM buildcolumnheaderstabletypes USING icolumncaptions[].

* Add a html header to the table
  CONCATENATE 'Dictionary object (Table Type)-' tablename INTO title SEPARATED BY space.
  PERFORM addhtmlheader USING ilochtml[]
                              title
                              addbackground
                              ss_table.

  APPEND '<body>' TO ilochtml.
  APPEND '  <table class="outerTable">' TO ilochtml.
  APPEND '    <tr>' TO ilochtml.
  CONCATENATE '      <td><h2>Table: ' tablename '</h2>' INTO wahtml.
  APPEND wahtml TO ilochtml.
  CONCATENATE '  <h3>Description: ' tabletitle '</h3></td>' INTO wahtml.
  APPEND wahtml TO ilochtml.
  APPEND '    </tr>' TO ilochtml.

  APPEND '    <tr>' TO ilochtml.
  APPEND '      <td><!--This is where our main table begins  -->' TO ilochtml.
  APPEND '<table class="innerTable">' TO ilochtml.

* This is where the header fields are defined
  APPEND '<tr>' TO ilochtml.
  LOOP AT icolumncaptions.
    CONCATENATE '  <th>' icolumncaptions '</th>' INTO wahtml.
    APPEND wahtml TO ilochtml.
  ENDLOOP.
  APPEND '</tr>' TO ilochtml.

* Add the table cells here
  LOOP AT iloctabletypes ASSIGNING <iloctabletype>.
    APPEND '<tr class="cell">' TO ilochtml.
    rowcounter = rowcounter + 1.
    CONCATENATE '  <td>' rowcounter '</td>' INTO wahtml.
    APPEND wahtml TO ilochtml.

    DO.
*     Assign each field in the table to the field symbol
      ASSIGN COMPONENT sy-index OF STRUCTURE <iloctabletype> TO <fsfield>.
      IF sy-subrc = 0.
        MOVE <fsfield> TO wtextcell.
        wahtml = '  <td>'.

*       Add the caption name
        IF wtextcell IS INITIAL.
          CONCATENATE wahtml '&nbsp;' '</td>' INTO wahtml.
        ELSE.
          CONCATENATE wahtml wtextcell '</td>' INTO wahtml.
        ENDIF.

        APPEND wahtml TO ilochtml.
        CLEAR wahtml.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

    APPEND '</tr>' TO ilochtml.
  ENDLOOP.

  APPEND '      </table>' TO ilochtml.
  APPEND '     </td>' TO ilochtml.
  APPEND '   </tr>' TO ilochtml.

* Add a html footer to the table
  PERFORM addhtmlfooter USING ilochtml[].
ENDFORM.                                                                                  "convertTableTypeToHTML
"convertITABtoHtml

*----------------------------------------------------------------------------------------------------------------------
*  convertCodeToHtml... Builds an HTML table based upon a text table.
*----------------------------------------------------------------------------------------------------------------------
FORM convertcodetohtml USING icontents LIKE dumihtml[]
                             value(programname)
                             value(shortdescription)
                             value(sourcecodetype)
                             value(functiondocumentationexists)
                             value(ismainfunctioninclude)
                             value(htmlextension)
                             value(customernamerange)
                             value(getincludes)
                             value(getdictstructures)
                             value(addbackground) TYPE abap_bool.

  DATA: htmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: head(255).
  DATA: tail(255).
  DATA: mytabix TYPE sytabix.
  DATA: nextline TYPE sytabix.
  DATA: hyperlinkname TYPE string.
  DATA: copyofcurrentline TYPE string.
  DATA: currentlinelength TYPE i VALUE 0.
  DATA: copylinelength TYPE i VALUE 0.
  DATA: ignorefuturelines TYPE abap_bool VALUE false.
  DATA: foundasterix TYPE abap_bool VALUE false.
  DATA: lowercaselink TYPE string.
  DATA: wanextline TYPE string.
  DATA: wacontent TYPE string.
  DATA: incommentmode TYPE abap_bool VALUE 'X'.

* Add a html header to the table
  PERFORM addhtmlheader USING htmltable[]
                              programname
                              addbackground
                              ss_code.

  APPEND '<body>' TO htmltable.
* Prgroamname and description
  APPEND '<table class="outerTable">' TO htmltable.
  APPEND `  <tr class="normalBoldLarge">` TO htmltable.

  CONCATENATE `     <td><h2>Code listing for: ` programname `</h2>` INTO htmltable.
  APPEND htmltable.

  CONCATENATE `<h3> Description: ` shortdescription `</h3></td>` INTO htmltable.
  APPEND htmltable.
  APPEND `   </tr>` TO htmltable.

* Code
  APPEND `  <tr>` TO htmltable.
  APPEND `     <td>` TO htmltable.

* Table containing code
  APPEND `     <table class="innerTable">` TO htmltable.
  APPEND `       <tr>` TO htmltable.
  APPEND `          <td>` TO htmltable.


  LOOP AT icontents INTO wacontent.
    mytabix = sy-tabix.

    IF NOT ( wacontent IS INITIAL ).
      WHILE ( wacontent CS '<' OR wacontent CS '>' ).
        REPLACE '<' IN wacontent WITH lt.
        REPLACE '>' IN wacontent WITH gt.
      ENDWHILE.

      IF wacontent+0(1) <> asterix.
        IF mytabix = 1.
          APPEND `   <div class="code">` TO htmltable.
          incommentmode = false.
        ELSE.
          IF incommentmode = true.
            APPEND `   </div>` TO htmltable.
            incommentmode = false.
            APPEND `   <div class="code">` TO htmltable.
          ENDIF.
        ENDIF.

        currentlinelength = strlen( wacontent ).
        copyofcurrentline = wacontent.

*       Don't hyperlink anything for files of type documentation
        IF sourcecodetype <> is_documentation.
*         Check for any functions to highlight
          IF ( wacontent CS callfunction ) AND ( wacontent <> 'DESTINATION' ).
            nextline = mytabix + 1.
            READ TABLE icontents INTO wanextline INDEX nextline.
            TRANSLATE wanextline TO UPPER CASE.
            IF wanextline NS 'DESTINATION'.
              SHIFT copyofcurrentline LEFT DELETING LEADING space.

              copylinelength = strlen( copyofcurrentline ).

              SPLIT copyofcurrentline AT space INTO head tail.
              SPLIT tail AT space INTO head tail.
              SPLIT tail AT space INTO head tail.
*             Function name is now in head
              TRANSLATE head USING ''' '.
              SHIFT head LEFT DELETING LEADING space.

              TRY.
                  IF head+0(1) = 'Y' OR head+0(1) = 'Z' OR head+0(1) = 'y' OR head+0(1) = 'z' OR head CS customernamerange.
*                 Definately a customer function module
                    hyperlinkname = head.

                    IF sourcecodetype = is_function.
                      copyofcurrentline = 'call function <a href ="../'.
                    ELSE.
                      copyofcurrentline = 'call function <a href ="'.
                    ENDIF.

                    lowercaselink = hyperlinkname.
                    TRANSLATE lowercaselink TO LOWER CASE.
*                 If we are running on a non UNIX environment we will need to remove forward slashes
                    IF frontendopsystem = non_unix.
                      TRANSLATE lowercaselink USING '/_'.
                    ENDIF.

                    CONCATENATE copyofcurrentline
                                lowercaselink     "hyperlinkName
                                '/'
                                lowercaselink     "hyperlinkName
                                period htmlextension '">'
                                ''''
                                hyperlinkname
                                ''''
                                '</a>'
                                tail INTO copyofcurrentline.

*                 Pad the string back out with spaces
                    WHILE copylinelength < currentlinelength.
                      SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                      copylinelength = copylinelength + 1.
                    ENDWHILE.

                    wacontent = copyofcurrentline.
                  ENDIF.
                CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
              ENDTRY.
            ENDIF.
          ENDIF.
        ENDIF.

*       Check for any customer includes to hyperlink
        IF wacontent CS include OR wacontent CS lowinclude.
          SHIFT copyofcurrentline LEFT DELETING LEADING space.
          copylinelength = strlen( copyofcurrentline ).

          SPLIT copyofcurrentline AT space INTO head tail.
          SHIFT tail LEFT DELETING LEADING space.

          TRY.
              IF ( tail+0(1) = 'Y' OR tail+0(1) = 'Z' OR tail+0(1) = 'y' OR tail+0(1) = 'z' OR tail CS customernamerange OR tail+0(2) = 'mz' OR tail+0(2) = 'MZ' )
                  AND NOT getincludes IS INITIAL AND  tail NS structure AND tail NS lowstructure.

*             Hyperlink for program includes
                CLEAR wacontent.
                SHIFT tail LEFT DELETING LEADING space.
                SPLIT tail AT period INTO hyperlinkname tail.
                copyofcurrentline = 'include <a href ="'.

                lowercaselink = hyperlinkname.
                TRANSLATE lowercaselink TO LOWER CASE.

*             If we are running on a non UNIX environment we will need to remove forward slashes
                IF frontendopsystem = non_unix.
                  TRANSLATE lowercaselink USING '/_'.
                ENDIF.

                CONCATENATE copyofcurrentline
                            lowercaselink       "hyperlinkName
                            period htmlextension '">'
                            hyperlinkname
                            '</a>'
                            period tail INTO copyofcurrentline.

*             Pad the string back out with spaces
                WHILE copylinelength < currentlinelength.
                  SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                  copylinelength = copylinelength + 1.
                ENDWHILE.
                wacontent = copyofcurrentline.
              ELSE.
                IF NOT getdictstructures IS INITIAL.
*              Hyperlink for structure include e.g. "include structure zfred."
                  copylinelength = strlen( copyofcurrentline ).
                  SPLIT copyofcurrentline AT space INTO head tail.
                  SHIFT tail LEFT DELETING LEADING space.
                  SPLIT tail AT space INTO head tail.

                  TRY.
                      IF tail+0(1) = 'Y' OR tail+0(1) = 'Z' OR tail+0(1) = 'y' OR tail+0(1) = 'z' OR tail CS customernamerange.
                        CLEAR wacontent.
                        SHIFT tail LEFT DELETING LEADING space.
                        SPLIT tail AT period INTO hyperlinkname tail.
                        copyofcurrentline = 'include structure <a href ='.

                        lowercaselink = hyperlinkname.
                        TRANSLATE lowercaselink TO LOWER CASE.
*                  If we are running on a non UNIX environment we will need to remove forward slashes
                        IF frontendopsystem = non_unix.
                          TRANSLATE lowercaselink USING '/_'.
                        ENDIF.

                        CONCATENATE copyofcurrentline
                                    '"'
                                    lowercaselink    "hyperlinkName
                                    '/'
                                    'dictionary-'
                                    lowercaselink    "hyperlinkName
                                    period htmlextension
                                    '">'
                                    hyperlinkname
                                    '</a>'
                                    period tail INTO copyofcurrentline.

*                  Pad the string back out with spaces
                        WHILE copylinelength < currentlinelength.
                          SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                          copylinelength = copylinelength + 1.
                        ENDWHILE.
                        wacontent = copyofcurrentline.
                      ENDIF.
                    CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
                  ENDTRY.
                ENDIF.
              ENDIF.
            CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
          ENDTRY.
        ENDIF.
      ELSE.
        IF  wacontent+0(1) = asterix.
          IF mytabix = 1.
            APPEND `   <div class="codeComment">` TO htmltable.
            incommentmode = true.
          ELSE.
            IF incommentmode = false.
              APPEND `   </div>` TO htmltable.
              APPEND `   <div class="codeComment">` TO htmltable.
              incommentmode = true.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.


      IF incommentmode = true.
        WHILE wacontent CS ' '.
          REPLACE space WITH '&nbsp;' INTO wacontent.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
        ENDWHILE.
      ENDIF.
      htmltable =  wacontent.

      TRY.
          IF htmltable+0(1) = ` `.
            WHILE htmltable CS ` `.
              REPLACE ` ` WITH '&nbsp;' INTO htmltable.
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.
            ENDWHILE.
          ENDIF.
        CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
      ENDTRY.
    ELSE.
      htmltable = ''.
    ENDIF.
    CONCATENATE htmltable `<br />` INTO htmltable.
    APPEND htmltable.
  ENDLOOP.

  APPEND `            </div>` TO htmltable.
  APPEND `          </td>`  TO htmltable.
  APPEND `        </tr>` TO htmltable.
  APPEND `      </table>` TO htmltable.
  APPEND `      </td>` TO htmltable.
  APPEND `      </tr>` TO htmltable.

* Add a html footer to the table
  PERFORM addhtmlfooter USING htmltable[].

  icontents[] = htmltable[].
ENDFORM.                                                                                             "convertCodeToHtml

*----------------------------------------------------------------------------------------------------------------------
*  convertClassToHtml... Builds an HTML table based upon a text table.
*----------------------------------------------------------------------------------------------------------------------
FORM convertclasstohtml USING icontents LIKE dumihtml[]
                              value(classname)
                              value(shortdescription)
                              value(sourcecodetype)
                              value(htmlextension)
                              value(customernamerange)
                              value(getdictstructures)
                              value(addbackground) TYPE abap_bool.

  DATA: htmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: mytabix TYPE sytabix.
  DATA: wacontent TYPE string.
  DATA: head TYPE string.
  DATA: tail TYPE string.
  DATA: hyperlinkname TYPE string.
  DATA: lowercaselink TYPE string.
  DATA: copyofcurrentline TYPE string.
  DATA: currentlinelength TYPE i VALUE 0.
  DATA: copylinelength TYPE i VALUE 0.
  DATA: incommentmode TYPE abap_bool VALUE 'X'.
  DATA: methoddirectory TYPE string.

* Add a html header to the table
  PERFORM addhtmlheader USING htmltable[]
                              classname
                              addbackground
                              ss_code.

  APPEND '<body>' TO htmltable.
* Class name and description
  APPEND '<table class="outerTable">' TO htmltable.
  APPEND `  <tr class="normalBoldLarge">` TO htmltable.

  CONCATENATE `     <td><h2>Code listing for class: ` classname `</h2>` INTO htmltable.
  APPEND htmltable.

  CONCATENATE `<h3> Description: ` shortdescription `</h3></td>` INTO htmltable.
  APPEND htmltable.
  APPEND `   </tr>` TO htmltable.

* Code
  APPEND `  <tr>` TO htmltable.
  APPEND `     <td>` TO htmltable.

* Table containing code
  APPEND `     <table class="innerTable">` TO htmltable.
  APPEND `       <tr>` TO htmltable.
  APPEND `          <td>` TO htmltable.


  LOOP AT icontents INTO wacontent.
    mytabix = sy-tabix.

*   Comments
    IF NOT ( wacontent IS INITIAL ).
      IF wacontent+0(1) = asterix.
        htmltable = wacontent.
        IF mytabix = 1.
          APPEND `   <div class="codeComment">` TO htmltable.
          incommentmode = true.
        ELSE.
          IF incommentmode = false.
            APPEND `   </div>` TO htmltable.
            APPEND `   <div class="codeComment">` TO htmltable.
            incommentmode = true.
          ENDIF.
        ENDIF.
      ELSE.
        IF mytabix = 1.
          APPEND `   <div class="code">` TO htmltable.
          incommentmode = false.
        ELSE.
          IF incommentmode = true.
            APPEND `   </div>` TO htmltable.
            incommentmode = false.
            APPEND `   <div class="code">` TO htmltable.
          ENDIF.
        ENDIF.

*        Smaller than, greater than signs
        IF NOT ( wacontent IS INITIAL ).
          WHILE ( wacontent CS '<' OR wacontent CS '>' ).
            REPLACE '<' IN wacontent WITH lt.
            REPLACE '>' IN wacontent WITH gt.
          ENDWHILE.

*--        Hyperlink methods in the class
*--        Setup sudirectory where method will be saved
          IF wacontent CS 'public section.'.
            methoddirectory = 'public_methods'.
          ELSEIF wacontent CS 'private section.'.
            methoddirectory = 'private_methods'.
          ELSEIF wacontent CS 'protected section.'.
            methoddirectory = 'protected_methods'.
          ENDIF.

*--        When it is a method, make a link
          FIND REGEX '([:space:]*methods[:space:]*)(.*)' IN wacontent
                                                         IGNORING CASE
                                                         SUBMATCHES head hyperlinkname.

          IF sy-subrc = 0.
            SHIFT hyperlinkname LEFT DELETING LEADING space.
            CONCATENATE methoddirectory
                        '/'
                        hyperlinkname
                        '.html'
                        INTO lowercaselink.

            TRANSLATE lowercaselink TO LOWER CASE.
            CONCATENATE head
                        ' <a href="'
                        lowercaselink
                        '">'
                        hyperlinkname
                        '</a>'
                        INTO wacontent.
            SHIFT wacontent RIGHT BY 2 PLACES.
          ENDIF.

*          Dictionary structures
          IF NOT getdictstructures IS INITIAL.
            FIND 'class' IN wacontent IGNORING CASE.
            IF sy-subrc <> 0.
*              Hyperlink for dictionary/structure include
              copylinelength = strlen( wacontent ).
              copyofcurrentline = wacontent.
              SPLIT copyofcurrentline AT space INTO head tail.
              SHIFT tail LEFT DELETING LEADING space.
              SPLIT tail AT space INTO head tail.

              TRY.
                  IF tail+0(1) = 'Y' OR tail+0(1) = 'Z' OR tail+0(1) = 'y' OR tail+0(1) = 'z' OR tail CS customernamerange.
                    CLEAR wacontent.
                    SHIFT tail LEFT DELETING LEADING space.
                    SPLIT tail AT period INTO hyperlinkname tail.
                    copyofcurrentline = 'include structure <a href ='.

                    lowercaselink = hyperlinkname.
                    TRANSLATE lowercaselink TO LOWER CASE.
*                  If we are running on a non UNIX environment we will need to remove forward slashes
                    IF frontendopsystem = non_unix.
                      TRANSLATE lowercaselink USING '/_'.
                    ENDIF.

                    CONCATENATE copyofcurrentline
                                '"'
                                lowercaselink    "hyperlinkName
                                '/'
                                'dictionary-'
                                lowercaselink    "hyperlinkName
                                period htmlextension
                                '">'
                                hyperlinkname
                                '</a>'
                                period tail INTO copyofcurrentline.

*                  Pad the string back out with spaces
                    WHILE copylinelength < currentlinelength.
                      SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                      copylinelength = copylinelength + 1.
                    ENDWHILE.
                    wacontent = copyofcurrentline.
                  ENDIF.
                CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
              ENDTRY.
            ENDIF.
          ENDIF.

          htmltable = wacontent.

          TRY.
              IF htmltable+0(1) = ` `.
                WHILE htmltable CS ` `.
                  REPLACE ` ` WITH '&nbsp;' INTO htmltable.
                  IF sy-subrc <> 0.
                    EXIT.
                  ENDIF.
                ENDWHILE.
              ENDIF.
            CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
          ENDTRY.
        ELSE.
          htmltable = ''.
        ENDIF.
      ENDIF.
    ELSE.
      htmltable = ''.
    ENDIF.

    CONCATENATE htmltable '<br />' INTO htmltable.
    APPEND htmltable.
  ENDLOOP.

  APPEND `            </div>` TO htmltable.
  APPEND `          </td>`  TO htmltable.
  APPEND `        </tr>` TO htmltable.
  APPEND `      </table>` TO htmltable.
  APPEND `      </td>` TO htmltable.
  APPEND `      </tr>` TO htmltable.

* Add a html footer to the table
  PERFORM addhtmlfooter USING htmltable[].

  icontents[] = htmltable[].
ENDFORM.                                                                                            "convertClassToHtml

*----------------------------------------------------------------------------------------------------------------------
*  convertFunctionToHtml... Builds an HTML table based upon a text table.
*----------------------------------------------------------------------------------------------------------------------
FORM convertfunctiontohtml USING icontents LIKE dumihtml[]
                                 value(functionname)
                                 value(shortdescription)
                                 value(sourcecodetype)
                                 value(functiondocumentationexists)
                                 value(ismainfunctioninclude)
                                 value(htmlextension)
                                 value(customernamerange)
                                 value(getincludes)
                                 value(getdictstructures)
                                 value(addbackground) TYPE abap_bool.

  DATA: htmltable TYPE STANDARD TABLE OF string WITH HEADER LINE.
  DATA: head(255).
  DATA: tail(255).
  DATA: mytabix TYPE sytabix.
  DATA: nextline TYPE sytabix.
  DATA: hyperlinkname TYPE string.
  DATA: copyofcurrentline TYPE string.
  DATA: currentlinelength TYPE i VALUE 0.
  DATA: copylinelength TYPE i VALUE 0.
  DATA: ignorefuturelines TYPE abap_bool VALUE false.
  DATA: foundasterix TYPE abap_bool VALUE false.
  DATA: lowercaselink TYPE string.
  DATA: wanextline TYPE string.
  DATA: wacontent TYPE string.
  DATA: incommentmode TYPE abap_bool VALUE 'X'.

* Add a html header to the table
  PERFORM addhtmlheader USING htmltable[]
                              functionname
                              addbackground
                              ss_code.

  APPEND '<body>' TO htmltable.
* Class name and description
  APPEND '<table class="outerTable">' TO htmltable.
  APPEND `  <tr class="normalBoldLarge">` TO htmltable.

  CONCATENATE `     <td><h2>Code listing for function ` functionname `</h2>` INTO htmltable.
  APPEND htmltable.

  CONCATENATE `<h3> Description: ` shortdescription `</h3></td>` INTO htmltable.
  APPEND htmltable.
  APPEND `   </tr>` TO htmltable.

* Code
  APPEND `  <tr>` TO htmltable.
  APPEND `     <td>` TO htmltable.

* Table containing code
  APPEND `     <table class="innerTable">` TO htmltable.
  APPEND `       <tr>` TO htmltable.
  APPEND `          <td>` TO htmltable.

  LOOP AT icontents INTO wacontent.
    mytabix = sy-tabix.

*   Extra code for adding global and doc hyperlinks to functions
    IF sourcecodetype = is_function AND ismainfunctioninclude = true.
      IF NOT ( wacontent IS INITIAL ).
        IF sy-tabix > 1.
          IF wacontent+0(1) = asterix AND ignorefuturelines = false.
            foundasterix = true.
          ELSE.
            IF foundasterix = true.
*             Lets add our extra HTML lines in here
              APPEND '' TO htmltable.

*             Global data hyperlink
              copyofcurrentline = '<div class="codeComment">*       <a href ="' .
              lowercaselink = functionname.
              TRANSLATE lowercaselink TO LOWER CASE.
*             If we are running on a non UNIX environment we will need to remove forward slashes
              IF frontendopsystem = non_unix.
                TRANSLATE lowercaselink USING '/_'.
              ENDIF.

              CONCATENATE copyofcurrentline 'global-' lowercaselink  "functionName
                          period htmlextension '">' 'Global data declarations' '</a>' INTO copyofcurrentline.

              CONCATENATE copyofcurrentline '</div><br />' INTO copyofcurrentline.

              APPEND copyofcurrentline TO htmltable.

*             Documentation hyperlink.
              IF functiondocumentationexists = true.
                copyofcurrentline = '<div class="codeComment">*       <a href ="'.

                lowercaselink = functionname.
                TRANSLATE lowercaselink TO LOWER CASE.
*               If we are running on a non UNIX environment we will need to remove forward slashes
                IF frontendopsystem = non_unix.
                  TRANSLATE lowercaselink USING '/_'.
                ENDIF.

                CONCATENATE copyofcurrentline
                            'docs-'
                            lowercaselink  "functionName
                            period htmlextension '">'
                            'Function module documentation'
                            '</a>'
                            INTO copyofcurrentline.

                CONCATENATE copyofcurrentline '</div><br />' INTO copyofcurrentline.
                APPEND copyofcurrentline TO htmltable.
              ENDIF.

              foundasterix = false.
              ignorefuturelines = true.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

*   Carry on as normal
    IF NOT ( wacontent IS INITIAL ).
      WHILE ( wacontent CS '<' OR wacontent CS '>' ).
        REPLACE '<' IN wacontent WITH lt.
        REPLACE '>' IN wacontent WITH gt.
      ENDWHILE.

      IF wacontent+0(1) <> asterix.
        IF mytabix = 1.
          APPEND `   <div class="code">` TO htmltable.
          incommentmode = false.
        ELSE.
          IF incommentmode = true.
            APPEND `   </div>` TO htmltable.
            incommentmode = false.
            APPEND `   <div class="code">` TO htmltable.
          ENDIF.
        ENDIF.

        currentlinelength = strlen( wacontent ).

*       Don't hyperlink anything for files of type documentation
        IF sourcecodetype <> is_documentation.
*       Check for any functions to highlight
          IF ( wacontent CS callfunction ) AND ( wacontent <> 'DESTINATION' ).
            nextline = mytabix + 1.
            READ TABLE icontents INTO wanextline INDEX nextline.
            TRANSLATE wanextline TO UPPER CASE.
            IF wanextline NS 'DESTINATION'.
              copyofcurrentline = wacontent.
              SHIFT copyofcurrentline LEFT DELETING LEADING space.

              copylinelength = strlen( copyofcurrentline ).

              SPLIT copyofcurrentline AT space INTO head tail.
              SPLIT tail AT space INTO head tail.
              SPLIT tail AT space INTO head tail.
*             Function name is now in head
              TRANSLATE head USING ''' '.
              SHIFT head LEFT DELETING LEADING space.

              TRY.
                  IF head+0(1) = 'Y' OR head+0(1) = 'Z' OR head+0(1) = 'y' OR head+0(1) = 'z' OR head CS customernamerange.

*                 Definately a customer function module
                    hyperlinkname = head.

                    IF sourcecodetype = is_function.
                      copyofcurrentline = 'call function <a href ="../'.
                    ELSE.
                      copyofcurrentline = 'call function <a href ="'.
                    ENDIF.

                    lowercaselink = hyperlinkname.
                    TRANSLATE lowercaselink TO LOWER CASE.
*                 If we are running on a non UNIX environment we will need to remove forward slashes
                    IF frontendopsystem = non_unix.
                      TRANSLATE lowercaselink USING '/_'.
                    ENDIF.

                    CONCATENATE copyofcurrentline
                                lowercaselink     "hyperlinkName
                                '/'
                                lowercaselink     "hyperlinkName
                                period htmlextension '">'
                                ''''
                                hyperlinkname
                                ''''
                                '</a>'
                                tail INTO copyofcurrentline.

*                 Pad the string back out with spaces
                    WHILE copylinelength < currentlinelength.
                      SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                      copylinelength = copylinelength + 1.
                    ENDWHILE.

                    wacontent = copyofcurrentline.
                  ENDIF.
                CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
              ENDTRY.
            ENDIF.
          ENDIF.
        ENDIF.

*       Check for any customer includes to hyperlink
        IF wacontent CS include OR wacontent CS lowinclude.
          copyofcurrentline = wacontent.

          SHIFT copyofcurrentline LEFT DELETING LEADING space.
          copylinelength = strlen( copyofcurrentline ).

          SPLIT copyofcurrentline AT space INTO head tail.
          SHIFT tail LEFT DELETING LEADING space.

          TRY.
              IF ( tail+0(1) = 'Y' OR tail+0(1) = 'Z' OR tail+0(1) = 'y' OR tail+0(1) = 'z'
                   OR tail CS customernamerange OR tail+0(2) = 'mz' OR tail+0(2) = 'MZ' ) AND NOT getincludes IS INITIAL.

*             Hyperlink for program includes
                CLEAR wacontent.
                SHIFT tail LEFT DELETING LEADING space.
                SPLIT tail AT period INTO hyperlinkname tail.
                copyofcurrentline = 'include <a href ="'.

                lowercaselink = hyperlinkname.
                TRANSLATE lowercaselink TO LOWER CASE.
*             If we are running on a non UNIX environment we will need to remove forward slashes
                IF frontendopsystem = non_unix.
                  TRANSLATE lowercaselink USING '/_'.
                ENDIF.

                CONCATENATE copyofcurrentline
                            lowercaselink       "hyperlinkName
                            period htmlextension '">'
                            hyperlinkname
                            '</a>'
                            period tail INTO copyofcurrentline.

*             Pad the string back out with spaces
                WHILE copylinelength < currentlinelength.
                  SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                  copylinelength = copylinelength + 1.
                ENDWHILE.
                wacontent = copyofcurrentline.
              ELSE.
                IF NOT getdictstructures IS INITIAL.
*               Hyperlink for structure include
                  copylinelength = strlen( copyofcurrentline ).
                  SPLIT copyofcurrentline AT space INTO head tail.
                  SHIFT tail LEFT DELETING LEADING space.
                  SPLIT tail AT space INTO head tail.

                  TRY.
                      IF tail+0(1) = 'Y' OR tail+0(1) = 'Z' OR tail+0(1) = 'y' OR tail+0(1) = 'z' OR tail CS customernamerange.
                        CLEAR wacontent.
                        SHIFT tail LEFT DELETING LEADING space.
                        SPLIT tail AT period INTO hyperlinkname tail.
                        copyofcurrentline = 'include structure <a href ='.

                        lowercaselink = hyperlinkname.
                        TRANSLATE lowercaselink TO LOWER CASE.
*                   If we are running on a non UNIX environment we will need to remove forward slashes
                        IF frontendopsystem = non_unix.
                          TRANSLATE lowercaselink USING '/_'.
                        ENDIF.

                        CONCATENATE copyofcurrentline
                                    '"'
                                    lowercaselink    "hyperlinkName
                                    '/'
                                    'dictionary-'
                                    lowercaselink    "hyperlinkName
                                    period htmlextension
                                    '">'
                                    hyperlinkname
                                    '</a>'
                                    period tail INTO copyofcurrentline.

*                   Pad the string back out with spaces
                        WHILE copylinelength < currentlinelength.
                          SHIFT copyofcurrentline RIGHT BY 1 PLACES.
                          copylinelength = copylinelength + 1.
                        ENDWHILE.
                        wacontent = copyofcurrentline.
                      ENDIF.
                    CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
                  ENDTRY.
                ENDIF.
              ENDIF.
            CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
          ENDTRY.
        ENDIF.
      ELSE.
        IF wacontent+0(1) = asterix.
          IF mytabix = 1.
            APPEND `   <div class="codeComment">` TO htmltable.
            incommentmode = true.
          ELSE.
            IF incommentmode = false.
              APPEND `   </div>` TO htmltable.
              APPEND `   <div class="codeComment">` TO htmltable.
              incommentmode = true.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      htmltable = wacontent.

      TRY.
          IF htmltable+0(1) = ` `.
            WHILE htmltable CS ` `.
              REPLACE ` ` WITH '&nbsp;' INTO htmltable.
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.
            ENDWHILE.
          ENDIF.
        CATCH cx_sy_range_out_of_bounds INTO objruntimeerror.
      ENDTRY.

    ELSE.
      htmltable = ''.
    ENDIF.
    CONCATENATE htmltable '<br />' INTO htmltable.
    APPEND htmltable.
  ENDLOOP.

  APPEND `            </div>` TO htmltable.
  APPEND `          </td>`  TO htmltable.
  APPEND `        </tr>` TO htmltable.
  APPEND `      </table>` TO htmltable.
  APPEND `      </td>` TO htmltable.
  APPEND `      </tr>` TO htmltable.

* Add a html footer to the table
  PERFORM addhtmlfooter USING htmltable[].

  icontents[] = htmltable[].
ENDFORM.                                                                                         "convertFunctionToHtml

*----------------------------------------------------------------------------------------------------------------------
*  buildColumnHeaders... build table column names
*----------------------------------------------------------------------------------------------------------------------
FORM buildddcolumnheaders USING iloccolumncaptions LIKE dumihtml[].

  APPEND 'Row' TO iloccolumncaptions.
  APPEND 'Field name' TO iloccolumncaptions.
  APPEND 'Position' TO iloccolumncaptions.
  APPEND 'Key' TO iloccolumncaptions.
  APPEND 'Data element' TO iloccolumncaptions.
  APPEND 'Domain' TO iloccolumncaptions.
  APPEND 'Datatype' TO iloccolumncaptions.
  APPEND 'Length' TO iloccolumncaptions.
  APPEND 'Lowercase' TO iloccolumncaptions.
  APPEND 'Domain text' TO iloccolumncaptions.
ENDFORM.                                                                                            "buildColumnHeaders

*----------------------------------------------------------------------------------------------------------------------
*  buildDomColumnHeaders... build table column names
*----------------------------------------------------------------------------------------------------------------------
FORM builddomcolumnheaders USING iloccolumncaptions LIKE dumihtml[].

  APPEND 'Domain Name' TO iloccolumncaptions.
  APPEND 'Value Low' TO iloccolumncaptions.
  APPEND 'Value High' TO iloccolumncaptions.
  APPEND 'Text' TO iloccolumncaptions.
ENDFORM.                    "buildDomColumnHeaders

*----------------------------------------------------------------------------------------------------------------------
*  buildColumnHeadersTableTypes
*----------------------------------------------------------------------------------------------------------------------
FORM buildcolumnheaderstabletypes  USING iloccolumncaptions LIKE dumihtml[].

  APPEND 'Row' TO iloccolumncaptions.
  APPEND 'Name of table type' TO iloccolumncaptions.
  APPEND 'Name of row type for table types' TO iloccolumncaptions.
  APPEND 'Category of table type (range or general table type)' TO iloccolumncaptions.
  APPEND 'Elem. type of LOW and HIGH components of a Ranges type' TO iloccolumncaptions.
  APPEND 'Type of Object Referenced' TO iloccolumncaptions.
  APPEND 'Initial Line Number for Table Types' TO iloccolumncaptions.
  APPEND 'Description' TO iloccolumncaptions.
ENDFORM.                                                                                 " BUILDCOLUMNHEADERSTABLETYPES


*----------------------------------------------------------------------------------------------------------------------
* addHTMLHeader...  add a html formatted header to our output table
*----------------------------------------------------------------------------------------------------------------------
FORM addhtmlheader USING ilocheader LIKE dumihtml[]
                         value(title)
                         value(addbackground) TYPE abap_bool
                         value(stylesheettype) TYPE char1.

  DATA: waheader TYPE string.

  APPEND '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">' TO ilocheader.
  APPEND '<html xmlns="http://www.w3.org/1999/xhtml">' TO ilocheader.
  APPEND '<head>' TO ilocheader.
*     append '<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />' to iLocHeader.
  APPEND '<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=ISO-8859-1" />' TO ilocheader.

  CONCATENATE '<title>' title '</title>' INTO waheader.
  APPEND waheader TO ilocheader.

  CASE stylesheettype.
    WHEN ss_code.
      PERFORM addcodestyles USING ilocheader
                                  addbackground.
    WHEN ss_table.
      PERFORM addtablestyles USING ilocheader
                                   addbackground.
  ENDCASE.

  PERFORM addgenericstyles USING ilocheader
                                 addbackground.

  APPEND '</head>' TO ilocheader.
ENDFORM.                                                                                                 "addHTMLHeader

*----------------------------------------------------------------------------------------------------------------------
* addCodeStyles... Add the stylesheets needed for HTML output
*----------------------------------------------------------------------------------------------------------------------
FORM addcodestyles USING ilocheader LIKE dumihtml[]
                         value(addbackground) TYPE abap_bool.

  APPEND '<style type="text/css">' TO ilocheader.
  APPEND `.code{ font-family:"Courier New", Courier, monospace; color:#000; font-size:14px; background-color:#F2F4F7 }` TO ilocheader.
  APPEND `  .codeComment {font-family:"Courier New", Courier, monospace; color:#0000F0; font-size:14px; background-color:#F2F4F7 }` TO ilocheader.
  APPEND `  .normalBold{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:12px; font-weight:800 }` TO ilocheader.
  APPEND `  .normalBoldLarge{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:16px; font-weight:800 }` TO ilocheader.
  APPEND '</style>' TO ilocheader.
ENDFORM.                    "addCodeStyles

*----------------------------------------------------------------------------------------------------------------------
* addTableStyles... Add the stylesheets needed for HTML output
*----------------------------------------------------------------------------------------------------------------------
FORM addtablestyles USING ilocheader LIKE dumihtml[]
                          value(addbackground) TYPE abap_bool.

  APPEND '<style type="text/css">' TO ilocheader.
  APPEND `  th{text-align:left}` TO ilocheader.

  APPEND `  .cell{` TO ilocheader.
  APPEND `     font-family:"Courier New", Courier, monospace;` TO ilocheader.
  APPEND `     color:#000;` TO ilocheader.
  APPEND `     font-size:12px;` TO ilocheader.
  APPEND `     background-color:#F2F4F7;` TO ilocheader.
  APPEND `  }` TO ilocheader.

  APPEND `  .cell td { border: thin solid #ccc; }` TO ilocheader.
  APPEND `</style>` TO ilocheader.
ENDFORM.                    "addTableStyles

*----------------------------------------------------------------------------------------------------------------------
* addTableStyles... Add the stylesheets needed for HTML output
*----------------------------------------------------------------------------------------------------------------------
FORM addgenericstyles USING ilocheader LIKE dumihtml[]
                          value(addbackground) TYPE abap_bool.

  APPEND '<style type="text/css">' TO ilocheader.

  APPEND `  .normal{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:12px }` TO ilocheader.
  APPEND `  .footer{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:12px; text-align: center }` TO ilocheader.
  APPEND `  h2{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:16px; font-weight:800 }` TO ilocheader.
  APPEND `  h3{ font-family:Arial, Helvetica, sans-serif; color:#000; font-size:14px; font-weight:800 }` TO ilocheader.

  APPEND `  .outerTable{` TO ilocheader.
  IF NOT addbackground IS INITIAL.
    APPEND `   background-color:#E0E7ED;` TO ilocheader.
  ENDIF.
  APPEND `   width:100%;` TO ilocheader.
  APPEND `   border-top-width: thin;` TO ilocheader.
  APPEND `   border-right-width: thin;` TO ilocheader.
  APPEND `   border-right-width: thin;` TO ilocheader.
  APPEND `   border-left-width: thin;` TO ilocheader.
  APPEND `   border-top-style: solid;` TO ilocheader.
  APPEND `   border-right-style: solid;` TO ilocheader.
  APPEND `   border-bottom-style: solid;` TO ilocheader.
  APPEND `   border-left-style: solid;` TO ilocheader.
  APPEND `  }` TO ilocheader.

  APPEND `  .innerTable{` TO ilocheader.
  IF NOT addbackground IS INITIAL.
    APPEND `   background-color:#F2F4F7;` TO ilocheader.
  ENDIF.
  APPEND `   width:100%;` TO ilocheader.
  APPEND `   border-top-width: thin;` TO ilocheader.
  APPEND `   border-right-width: thin;` TO ilocheader.
  APPEND `   border-bottom-width: thin;` TO ilocheader.
  APPEND `   border-left-width: thin;` TO ilocheader.
  APPEND `   border-top-style: solid;` TO ilocheader.
  APPEND `   border-right-style: solid;` TO ilocheader.
  APPEND `   border-bottom-style: solid;` TO ilocheader.
  APPEND `   border-left-style: solid;` TO ilocheader.
  APPEND `  }` TO ilocheader.
  APPEND '</style>' TO ilocheader.
ENDFORM.                    "addGenericStyles

*----------------------------------------------------------------------------------------------------------------------
* addHTMLFooter...  add a html formatted footer to our output table
*----------------------------------------------------------------------------------------------------------------------
FORM addhtmlfooter USING ilocfooter LIKE dumihtml[].

  DATA: footermessage TYPE string.
  DATA: wafooter TYPE string.

  PERFORM buildfootermessage USING footermessage.

  APPEND `   <tr>` TO ilocfooter.
  CONCATENATE '<td class="footer">' footermessage '</td>' INTO wafooter.
  APPEND wafooter TO ilocfooter.
  APPEND `   </tr>` TO ilocfooter.
  APPEND `</table>` TO ilocfooter.
  APPEND '</body>' TO ilocfooter.
  APPEND '</html>' TO ilocfooter.
ENDFORM.                                                                                                 "addHTMLFooter

*----------------------------------------------------------------------------------------------------------------------
* buildFooterMessage...Returns a footer message based on the output file type.
*----------------------------------------------------------------------------------------------------------------------
FORM buildfootermessage USING returnmessage.

  CONCATENATE `Extracted by Mass Download version `
              versionno ` - E.G.Mellodew. 1998-`
              sy-datum+0(4) `. Sap Release ` sy-saprl INTO returnmessage.
ENDFORM.                                                                                            "buildFooterMessage

***********************************************************************************************************************
********************************************DISPLAY ROUTINES***********************************************************
***********************************************************************************************************************

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodeTables...
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodetables USING ilocdictionary LIKE idictionary[]
                              iloctreedisplay LIKE itreedisplay[]
                              value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <wadictionary> TYPE tdicttable.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).
  DATA: sublevel TYPE string.

  tablelines = lines( ilocdictionary ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring 'table downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ELSE.
    CONCATENATE tablelinesstring 'tables downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ENDIF.

  WRITE runtime TO runtimechar.
  CONCATENATE watreedisplay-text2 '- runtime' runtimechar INTO watreedisplay-text2 SEPARATED BY space.

* include header display record.
  watreedisplay-tlevel = '1'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO iloctreedisplay.

  LOOP AT ilocdictionary ASSIGNING <wadictionary>.
    watreedisplay-tlevel = '2'.
    watreedisplay-text2 = <wadictionary>-tablename.
    watreedisplay-tcolor2    = 3.
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 3.
    watreedisplay-tpos3      = 60.
    CONCATENATE 'Dictionary:' <wadictionary>-tabletitle INTO watreedisplay-text3 SEPARATED BY space.

    APPEND watreedisplay TO iloctreedisplay.
  ENDLOOP.
ENDFORM.                                                                                            "fillTreeNodeTables

*-------------------------------------------------------------------------------------------------------
*   fillTreeNodeXslt...
*-------------------------------------------------------------------------------------------------------
FORM filltreenodexslt USING iloctransformations LIKE itransformations[]
                            iloctreedisplay LIKE itreedisplay[]
                            value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).

  tablelines = lines( iloctransformations ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring ` XSLT program downloaded` INTO watreedisplay-text2.
  ELSE.
    CONCATENATE tablelinesstring ` XSLT programs downloaded` INTO watreedisplay-text2.
  ENDIF.

  WRITE runtime TO runtimechar.

  CONCATENATE watreedisplay-text2 ` - runtime ` runtimechar INTO watreedisplay-text2.
* include header display record.
  watreedisplay-tlevel = '2'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO itreedisplay.

  LOOP AT iloctransformations ASSIGNING <watransformation>.
*   Main programs.
    watreedisplay-tlevel = '3'.
    watreedisplay-text2 = <watransformation>-xsltname.
    watreedisplay-tcolor2    = 1.
*   Description
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 1.
    watreedisplay-tpos3      = 60.
    CONCATENATE `XSLT: ` <watransformation>-xsltdesc INTO watreedisplay-text3.
    APPEND watreedisplay TO itreedisplay.
  ENDLOOP.
ENDFORM.                                                                           " FILLTREENODEXSLT

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodeMessages...
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodemessages USING ilocmessages LIKE imessages[]
                                iloctreedisplay LIKE itreedisplay[]
                                value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <wamessage> TYPE tmessage.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).

  SORT ilocmessages ASCENDING BY arbgb.

  LOOP AT ilocmessages ASSIGNING <wamessage>.
    AT NEW arbgb.
      tablelines = tablelines + 1.
    ENDAT.
  ENDLOOP.
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring 'message class downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ELSE.
    CONCATENATE tablelinesstring 'message classes downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ENDIF.

  WRITE runtime TO runtimechar.
  CONCATENATE watreedisplay-text2 '- runtime' runtimechar INTO watreedisplay-text2 SEPARATED BY space.

* include header display record.
  watreedisplay-tlevel = '1'.
  watreedisplay-tlength2 = 60.
  watreedisplay-tcolor2 = 1.
  APPEND watreedisplay TO iloctreedisplay.

  LOOP AT ilocmessages ASSIGNING <wamessage>.
    AT NEW arbgb.
      watreedisplay-tlevel = '2'.
      watreedisplay-text2 = <wamessage>-arbgb.
      watreedisplay-tcolor2    = 5.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 5.
      watreedisplay-tpos3      = 60.
      watreedisplay-text3 = <wamessage>-stext.
      CONCATENATE 'Message class:'  watreedisplay-text3 INTO watreedisplay-text3 SEPARATED BY space.
      APPEND watreedisplay TO iloctreedisplay.
    ENDAT.
  ENDLOOP.
ENDFORM.                                                                                          "fillTreeNodeMessages

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodeTableTypes
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodetabletypes USING iloctabletypes LIKE itabletypes[]
                                  iloctreedisplay LIKE itreedisplay[]
                                  value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <watabletype> LIKE LINE OF iloctabletypes.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).
  DATA: sublevel TYPE string.

  tablelines = lines( iloctabletypes ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring 'table type downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ELSE.
    CONCATENATE tablelinesstring 'table types downloaded' INTO watreedisplay-text2 SEPARATED BY space.
  ENDIF.

  WRITE runtime TO runtimechar.
  CONCATENATE watreedisplay-text2 '- runtime' runtimechar INTO watreedisplay-text2 SEPARATED BY space.

* include header display record.
  watreedisplay-tlevel = '2'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO iloctreedisplay.

  LOOP AT iloctabletypes ASSIGNING <watabletype>.
    watreedisplay-tlevel = '3'.
    watreedisplay-text2 = <watabletype>-typename.
    watreedisplay-tcolor2    = 3.
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 3.
    watreedisplay-tpos3      = 60.
    CONCATENATE 'Dictionary:' <watabletype>-ddtext INTO watreedisplay-text3 SEPARATED BY space.

    APPEND watreedisplay TO iloctreedisplay.
  ENDLOOP.
ENDFORM.                                                                                        " FILLTREENODETABLETYPES

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodeFunctions...
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodefunctions USING ilocfunctions LIKE ifunctions[]
                                 iloctreedisplay LIKE itreedisplay[]
                                 value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <wafunction> TYPE tfunction.
  FIELD-SYMBOLS: <wascreen> TYPE tscreenflow.
  FIELD-SYMBOLS: <waguititle> TYPE tguititle.
  FIELD-SYMBOLS: <wadictionary> TYPE tdicttable.
  FIELD-SYMBOLS: <wainclude> TYPE tinclude.
  FIELD-SYMBOLS: <wamessage> TYPE tmessage.
  FIELD-SYMBOLS: <watabletype> TYPE ttabletype.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).

  SORT ilocfunctions ASCENDING BY functionname.

  tablelines = lines( ilocfunctions ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring ` function downloaded` INTO watreedisplay-text2.
  ELSE.
    CONCATENATE tablelinesstring ` functions downloaded` INTO watreedisplay-text2.
  ENDIF.

  WRITE runtime TO runtimechar.

  CONCATENATE watreedisplay-text2 ` - runtime ` runtimechar INTO watreedisplay-text2.
* include header display record.
  watreedisplay-tlevel = '1'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO iloctreedisplay.

* Lets fill the detail in
  LOOP AT ilocfunctions ASSIGNING <wafunction>.
    watreedisplay-tlevel = 2.
    watreedisplay-text2 = <wafunction>-functionname.
    watreedisplay-tcolor2    = 7.
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 7.
    watreedisplay-tpos3      = 60.
    CONCATENATE `Function: ` <wafunction>-functionname INTO watreedisplay-text3.
    APPEND watreedisplay TO iloctreedisplay.

*   Screens.
    LOOP AT <wafunction>-iscreenflow ASSIGNING <wascreen>.
      watreedisplay-tlevel = '2'.
      watreedisplay-text2 = <wascreen>-screen.
      watreedisplay-tcolor2    = 6.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 6.
      watreedisplay-tpos3      = 60.
      watreedisplay-text3 = 'Screen'.
      APPEND watreedisplay TO itreedisplay.
    ENDLOOP.

*   GUI Title.
    LOOP AT <wafunction>-iguititle ASSIGNING <waguititle>.
      watreedisplay-tlevel = '2'.
      watreedisplay-text2 = <waguititle>-obj_code.
      watreedisplay-tcolor2    = 6.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 6.
      watreedisplay-tpos3      = 60.
      watreedisplay-text3 = 'GUI Title'.
      APPEND watreedisplay TO itreedisplay.
    ENDLOOP.

*   Fill in the tree with include information
    LOOP AT <wafunction>-iincludes ASSIGNING <wainclude>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wainclude>-includename.
      watreedisplay-tcolor2    = 4.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 4.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Include:   ` <wainclude>-includetitle INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with dictionary information
    LOOP AT <wafunction>-idictstruct ASSIGNING <wadictionary>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wadictionary>-tablename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Dictionary:` <wadictionary>-tabletitle INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with Table type information
    LOOP AT <wafunction>-itabletypes ASSIGNING <watabletype>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watabletype>-typename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watabletype>-ddtext INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with transformation information
    LOOP AT <wafunction>-itransformations[] ASSIGNING <watransformation>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watransformation>-xsltname.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watransformation>-xsltdesc INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with message information
    SORT <wafunction>-imessages[] ASCENDING BY arbgb.
    LOOP AT <wafunction>-imessages ASSIGNING <wamessage>.
      AT NEW arbgb.
        watreedisplay-tlevel = 3.
        watreedisplay-text2 = <wamessage>-arbgb.
        watreedisplay-tcolor2    = 5.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 5.
        watreedisplay-tpos3      = 60.

*       Select the message class text if we do not have it already
        IF <wamessage>-stext IS INITIAL.
          SELECT SINGLE stext FROM t100a
                              INTO <wamessage>-stext
                              WHERE arbgb = <wamessage>-arbgb.
        ENDIF.

        watreedisplay-text3 = <wamessage>-stext.
        CONCATENATE `Message class: `  watreedisplay-text3 INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDAT.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                                                                                         "fillTreeNodeFunctions

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodePrograms
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodeprograms USING ilocprograms LIKE iprograms[]
                                ilocfunctions LIKE ifunctions[]
                                iloctreedisplay LIKE itreedisplay[]
                                value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <waprogram> TYPE tprogram.
  FIELD-SYMBOLS: <wascreen> TYPE tscreenflow.
  FIELD-SYMBOLS: <wafunction> TYPE tfunction.
  FIELD-SYMBOLS: <wadictionary> TYPE tdicttable.
  FIELD-SYMBOLS: <wainclude> TYPE tinclude.
  FIELD-SYMBOLS: <wamessage> TYPE tmessage.
  FIELD-SYMBOLS: <watabletype> TYPE ttabletype.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).

  tablelines = lines( ilocprograms ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring ` program downloaded` INTO watreedisplay-text2.
  ELSE.
    CONCATENATE tablelinesstring ` programs downloaded` INTO watreedisplay-text2.
  ENDIF.

  WRITE runtime TO runtimechar.

  CONCATENATE watreedisplay-text2 ` - runtime ` runtimechar INTO watreedisplay-text2.
* include header display record.
  watreedisplay-tlevel = '1'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO itreedisplay.

  LOOP AT ilocprograms ASSIGNING <waprogram>.
*   Main programs.
    watreedisplay-tlevel = '2'.
    watreedisplay-text2 = <waprogram>-progname.
    watreedisplay-tcolor2    = 1.
*   Description
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 1.
    watreedisplay-tpos3      = 60.
    CONCATENATE `Program: ` <waprogram>-programtitle INTO watreedisplay-text3.
    APPEND watreedisplay TO itreedisplay.
*   Screens.
    LOOP AT <waprogram>-iscreenflow ASSIGNING <wascreen>.
      watreedisplay-tlevel = '3'.
      watreedisplay-text2 = <wascreen>-screen.
      watreedisplay-tcolor2    = 6.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 6.
      watreedisplay-tpos3      = 60.
      watreedisplay-text3 = 'Screen'.
      APPEND watreedisplay TO itreedisplay.
    ENDLOOP.
*   fill in the tree with message information
    SORT <waprogram>-imessages[] ASCENDING BY arbgb.
    LOOP AT <waprogram>-imessages ASSIGNING <wamessage>.
      AT NEW arbgb.
        watreedisplay-tlevel = 3.
        watreedisplay-text2 = <wamessage>-arbgb.
        watreedisplay-tcolor2    = 5.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 5.
        watreedisplay-tpos3      = 60.

*       Select the message class text if we do not have it already
        IF <wamessage>-stext IS INITIAL.
          SELECT SINGLE stext FROM t100a
                              INTO <wamessage>-stext
                              WHERE arbgb = <wamessage>-arbgb.
        ENDIF.

        watreedisplay-text3 = <wamessage>-stext.
        CONCATENATE `Message class: `  watreedisplay-text3 INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDAT.
    ENDLOOP.
*   Fill in the tree with include information
    LOOP AT <waprogram>-iincludes ASSIGNING <wainclude>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wainclude>-includename.
      watreedisplay-tcolor2    = 4.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 4.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Include:   ` <wainclude>-includetitle INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.
*   fill in the tree with dictionary information
    LOOP AT <waprogram>-idictstruct ASSIGNING <wadictionary>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wadictionary>-tablename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Dictionary:    ` <wadictionary>-tabletitle INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with Table type information
    LOOP AT <waprogram>-itabletypes ASSIGNING <watabletype>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watabletype>-typename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watabletype>-ddtext INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with transformation information
    LOOP AT <waprogram>-itransformations ASSIGNING <watransformation>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watransformation>-xsltname.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watransformation>-xsltdesc INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   Function Modules
    LOOP AT ilocfunctions ASSIGNING <wafunction> WHERE programlinkname = <waprogram>-progname.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 = <wafunction>-functionname.
      watreedisplay-tcolor2    = 7.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 7.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Function:      ` <wafunction>-functionname INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.

*     Fill in the tree with include information
      LOOP AT <wafunction>-iincludes ASSIGNING <wainclude>.
        watreedisplay-tlevel = 4.
        watreedisplay-text2 =  <wainclude>-includename.
        watreedisplay-tcolor2    = 4.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 4.
        watreedisplay-tpos3      = 60.
        CONCATENATE `Include:       ` <wainclude>-includetitle INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDLOOP.

*     fill in the tree with dictionary information
      LOOP AT <wafunction>-idictstruct ASSIGNING <wadictionary>.
        watreedisplay-tlevel = 4.
        watreedisplay-text2 =  <wadictionary>-tablename.
        watreedisplay-tcolor2    = 3.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 3.
        watreedisplay-tpos3      = 60.
        CONCATENATE `Dictionary:    ` <wadictionary>-tabletitle INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDLOOP.

*     fill in the tree with message information
      SORT <wafunction>-imessages[] ASCENDING BY arbgb.
      LOOP AT <wafunction>-imessages ASSIGNING <wamessage>.
        AT NEW arbgb.
          watreedisplay-tlevel = 4.
          watreedisplay-text2 = <wamessage>-arbgb.
          watreedisplay-tcolor2    = 5.
          watreedisplay-tlength3   = 80.
          watreedisplay-tcolor3    = 5.
          watreedisplay-tpos3      = 60.

*         Select the message class text if we do not have it already
          IF <wamessage>-stext IS INITIAL.
            SELECT SINGLE stext FROM t100a
                                INTO <wamessage>-stext
                                WHERE arbgb = <wamessage>-arbgb.
          ENDIF.

          watreedisplay-text3 = <wamessage>-stext.
          CONCATENATE `Message class:  `  watreedisplay-text3 INTO watreedisplay-text3.
          APPEND watreedisplay TO iloctreedisplay.
        ENDAT.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                                                                                          "fillTreeNodePrograms

*----------------------------------------------------------------------------------------------------------------------
*  fillTreeNodeClasses
*----------------------------------------------------------------------------------------------------------------------
FORM filltreenodeclasses USING ilocclasses LIKE iclasses[]
                               ilocfunctions LIKE ifunctions[]
                               iloctreedisplay LIKE itreedisplay[]
                               value(runtime).

  DATA: tablelines TYPE i.
  DATA: watreedisplay LIKE snodetext.
  FIELD-SYMBOLS: <waclass> TYPE tclass.
  FIELD-SYMBOLS: <wamethod> TYPE tmethod.
  FIELD-SYMBOLS: <wafunction> TYPE tfunction.
  FIELD-SYMBOLS: <wadictionary> TYPE tdicttable.
  FIELD-SYMBOLS: <wainclude> TYPE tinclude.
  FIELD-SYMBOLS: <wamessage> TYPE tmessage.
  FIELD-SYMBOLS: <watabletype> TYPE ttabletype.
  FIELD-SYMBOLS: <watransformation> TYPE ttransformation.
  DATA: tablelinesstring TYPE string.
  DATA: runtimechar(10).

  tablelines = lines( ilocclasses ).
  tablelinesstring = tablelines.

  IF tablelines = 1.
    CONCATENATE tablelinesstring ` class downloaded` INTO watreedisplay-text2.
  ELSE.
    CONCATENATE tablelinesstring ` classes downloaded` INTO watreedisplay-text2.
  ENDIF.

  WRITE runtime TO runtimechar.

  CONCATENATE watreedisplay-text2 ` - runtime ` runtimechar INTO watreedisplay-text2.
* include header display record.
  watreedisplay-tlevel = '1'.
  watreedisplay-tlength2  = 60.
  watreedisplay-tcolor2    = 1.
  APPEND watreedisplay TO itreedisplay.

  LOOP AT ilocclasses ASSIGNING <waclass>.
*   Main Class.
    watreedisplay-tlevel = '2'.
    watreedisplay-text2 = <waclass>-clsname.
    watreedisplay-tcolor2    = 1.
*   Description
    watreedisplay-tlength3   = 80.
    watreedisplay-tcolor3    = 1.
    watreedisplay-tpos3      = 60.
    CONCATENATE `Class:    ` <waclass>-descript INTO watreedisplay-text3.
    APPEND watreedisplay TO itreedisplay.

*   fill in the tree with method information
    LOOP AT <waclass>-imethods[] ASSIGNING <wamethod>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wamethod>-cmpname.
      watreedisplay-tcolor2    = 2.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 2.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Method:   ` <wamethod>-descript INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with message information
    SORT <waclass>-imessages[] ASCENDING BY arbgb.
    LOOP AT <waclass>-imessages ASSIGNING <wamessage>.
      AT NEW arbgb.
        watreedisplay-tlevel = 3.
        watreedisplay-text2 = <wamessage>-arbgb.
        watreedisplay-tcolor2    = 5.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 5.
        watreedisplay-tpos3      = 60.

*       Select the message class text if we do not have it already
        IF <wamessage>-stext IS INITIAL.
          SELECT SINGLE stext FROM t100a
                              INTO <wamessage>-stext
                              WHERE arbgb = <wamessage>-arbgb.
        ENDIF.

        watreedisplay-text3 = <wamessage>-stext.
        CONCATENATE `Message class: `  watreedisplay-text3 INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDAT.
    ENDLOOP.

*   fill in the tree with dictionary information
    LOOP AT <waclass>-idictstruct ASSIGNING <wadictionary>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <wadictionary>-tablename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Dictionary:    ` <wadictionary>-tabletitle INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with Table type information
    LOOP AT <waclass>-itabletypes ASSIGNING <watabletype>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watabletype>-typename.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watabletype>-ddtext INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   fill in the tree with transformation information
    LOOP AT <waclass>-itransformations ASSIGNING <watransformation>.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 =  <watransformation>-xsltname.
      watreedisplay-tcolor2    = 3.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 3.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Table Type:    ` <watransformation>-xsltdesc INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.
    ENDLOOP.

*   Function Modules
    LOOP AT ilocfunctions ASSIGNING <wafunction> WHERE programlinkname = <waclass>-clsname.
      watreedisplay-tlevel = 3.
      watreedisplay-text2 = <wafunction>-functionname.
      watreedisplay-tcolor2    = 7.
      watreedisplay-tlength3   = 80.
      watreedisplay-tcolor3    = 7.
      watreedisplay-tpos3      = 60.
      CONCATENATE `Function:      ` <wafunction>-functionname INTO watreedisplay-text3.
      APPEND watreedisplay TO iloctreedisplay.

*     Fill in the tree with include information
      LOOP AT <wafunction>-iincludes ASSIGNING <wainclude>.
        watreedisplay-tlevel = 4.
        watreedisplay-text2 =  <wainclude>-includename.
        watreedisplay-tcolor2    = 4.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 4.
        watreedisplay-tpos3      = 60.
        CONCATENATE `Include:       ` <wainclude>-includetitle INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDLOOP.

*     fill in the tree with dictionary information
      LOOP AT <wafunction>-idictstruct ASSIGNING <wadictionary>.
        watreedisplay-tlevel = 4.
        watreedisplay-text2 =  <wadictionary>-tablename.
        watreedisplay-tcolor2    = 3.
        watreedisplay-tlength3   = 80.
        watreedisplay-tcolor3    = 3.
        watreedisplay-tpos3      = 60.
        CONCATENATE `Dictionary:    ` <wadictionary>-tabletitle INTO watreedisplay-text3.
        APPEND watreedisplay TO iloctreedisplay.
      ENDLOOP.

*     fill in the tree with message information
      SORT <wafunction>-imessages[] ASCENDING BY arbgb.
      LOOP AT <wafunction>-imessages ASSIGNING <wamessage>.
        AT NEW arbgb.
          watreedisplay-tlevel = 4.
          watreedisplay-text2 = <wamessage>-arbgb.
          watreedisplay-tcolor2    = 5.
          watreedisplay-tlength3   = 80.
          watreedisplay-tcolor3    = 5.
          watreedisplay-tpos3      = 60.

*         Select the message class text if we do not have it already
          IF <wamessage>-stext IS INITIAL.
            SELECT SINGLE stext FROM t100a
                                INTO <wamessage>-stext
                                WHERE arbgb = <wamessage>-arbgb.
          ENDIF.

          watreedisplay-text3 = <wamessage>-stext.
          CONCATENATE `Message class:  `  watreedisplay-text3 INTO watreedisplay-text3.
          APPEND watreedisplay TO iloctreedisplay.
        ENDAT.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                                                                                           "fillTreeNodeClasses

*----------------------------------------------------------------------------------------------------------------------
* displayTree...
*----------------------------------------------------------------------------------------------------------------------
FORM displaytree USING iloctreedisplay LIKE itreedisplay[].

  DATA: watreedisplay TYPE snodetext.

* build up the tree from the internal table node
  CALL FUNCTION 'RS_TREE_CONSTRUCT'
    TABLES
      nodetab            = itreedisplay
    EXCEPTIONS
      tree_failure       = 1
      id_not_found       = 2
      wrong_relationship = 3
      OTHERS             = 4.

* get the first index and expand the whole tree
  READ TABLE iloctreedisplay INTO watreedisplay INDEX 1.
  CALL FUNCTION 'RS_TREE_EXPAND'
    EXPORTING
      node_id   = watreedisplay-id
      all       = 'X'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.

* now display the tree
  CALL FUNCTION 'RS_TREE_LIST_DISPLAY'
    EXPORTING
      callback_program      = sy-cprog
      callback_user_command = 'CB_USER_COMMAND'
      callback_text_display = 'CB_text_DISPLAY'
      callback_top_of_page  = 'TOP_OF_PAGE'
    EXCEPTIONS
      OTHERS                = 1.
ENDFORM.                                                                                                   "displayTree

*----------------------------------------------------------------------------------------------------------------------
*  topOfPage... for tree display routines.
*----------------------------------------------------------------------------------------------------------------------
FORM topofpage.

ENDFORM.                    "topOfPage
