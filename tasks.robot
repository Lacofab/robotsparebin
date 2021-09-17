*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               https://robotsparebinindustries.com/#/robot-order
...               https://robotsparebinindustries.com/orders.csv
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs
Library           RPA.RobotLogListener

*** Variables ***
${tmpDirectory}=    ${CURDIR}${/}tmp
${outputDirectory}=    ${CURDIR}${/}output


*** Keywords ***
Check Directories
    Create Directory    ${outputDirectory}
    Create Directory    ${tmpDirectory}
    ${files}=    List files in directory    ${tmpDirectory}
    FOR    ${file}  IN  @{FILES}
        ${fileFullPath}=    Catenate  ${tmpDirectory}${/}${file}
        Remove file    ${fileFullPath}
    END

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    robotsparebin
    Open Available Browser  ${secret}[url]
    Wait For Condition  return document.readyState=="complete"


*** Keywords ***
Get orders
    ${csv_url}=  Input form dialog
    Download   ${csv_url}  overwrite=true
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

*** Keywords ***
Input form dialog
    Add heading       Robot configuration
    Add text input    csv_path    label=Csv file URL   placeholder=Enter csv url here
    ${result}=    Run dialog
    [Return]    ${result.csv_path} 

*** Keywords ***
Close the annoying modal
    Click Element    //button[contains(.,'OK')]

*** Keywords ***
Fill the form
    [Arguments]  ${data}
    Select From List By Value    head     ${data}[Head]
    Select Radio Button    body    ${data}[Body]
    Input Text    //div[3]/input    ${data}[Legs]
    Input Text    address    ${data}[Address]  


*** Keywords ***
Preview the robot
    Click Button    preview

*** Keywords ***
Submit the order
    Mute Run On Failure    Wait Until Keyword Succeeds 
    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60x    1s    Pass the order  
    #Wait Until Keyword Succeeds    60x    1s    Pass the order    

*** Keywords ***
Pass the order
    Click Button    order
    Wait Until Page Contains Element    order-another

*** Keywords ***
Go to order another robot
    Click Button    order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]  ${orderNumber}
    Wait Until Element Is Visible    id:receipt
     ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
     Html To Pdf    ${receipt_html}    ${tmpDirectory}${/}${orderNumber}.pdf
     [Return]   ${tmpDirectory}${/}${orderNumber}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]  ${orderNumber}
    Screenshot    robot-preview-image    ${tmpDirectory}${/}${orderNumber}.png
    [Return]    ${tmpDirectory}${/}${orderNumber}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf    ${pdf}

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${tmpDirectory}      ${outputDirectory}${/}receipts.zip   include=*.pdf

# +
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Check Directories
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    
    [Teardown]  Close All Browsers
    
    
    
# -

