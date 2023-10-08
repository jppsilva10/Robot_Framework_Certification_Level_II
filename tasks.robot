*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Place orders    ${orders}

    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv

    RETURN    ${orders}

Place orders
    [Arguments]    ${orders}

    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
        Create a ZIP file of receipt PDF files
    END

Close the annoying modal
    Wait Until Element Is Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    OK

Fill the form
    [Arguments]    ${order}

    Set Local Variable    ${head_locator}    head
    Wait Until Element Is Visible    ${head_locator}
    Select From List By Value    ${head_locator}    ${order}[Head]

    Set Local Variable    ${body_locator}    body
    Wait Until Element Is Visible    ${body_locator}
    Select Radio Button    ${body_locator}    ${order}[Body]

    Set Local Variable    ${legs_locator}    //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input
    Wait Until Element Is Visible    ${legs_locator}
    Input Text    ${legs_locator}    ${order}[Legs]

    Set Local Variable    ${address_locator}    address
    Wait Until Element Is Visible    ${address_locator}
    Input Text    ${address_locator}    ${order}[Address]

Preview the robot
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}

    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdf_path}    ${CURDIR}${/}receipts${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}

    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${screenshot_path}    ${CURDIR}${/}screenshots${/}screenshot_${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}

    RETURN    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}
    ...    ${screenshot}

    ${myfiles}=    Create List    ${screenshot}

    Open PDF    ${pdf}
    Add Files To PDF    ${myfiles}    ${pdf}    ${True}
    Close PDF    ${pdf}

Go to order another robot
    Click button    id:order-another

Create a ZIP file of receipt PDF files
    Archive Folder With ZiP    ${CURDIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip

Close the browser
    Close Browser
