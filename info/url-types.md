1. /physical/file/path

properties:
- controller = irrelevant
- category = irrelevant
- fodlerindex = irrelevant
- context path = DriveLetter://app/path/physical/file/path
    {webAppPath}{urlPath}

decision: if addressed path exists on webserver under webfolder

2. /component

properties:
- controller = component -> function show-{controller} -> show-component
- category = irrelevant
- urlPath = custom logic
- fodlerindex = irrelevant
- context path = irrelevant

decision: if addressed function exists

3. /category[/0]

properties:
- controller = static -> function show-{controller} -> show-static
- category = category
- folderIndex = 0
- folderPath = DriveLetter://folder/path/in/settings
    {settings/sharedfolders}/{category}[{folderIndex}]
- urlPath = ''    
- contextPath = DriveLetter://folder/path/in/settings
    {folderPath}

decision: if category array exists in settings with the indexes path AND addressed path is exists on webserver 

4. /category/0/relative/path

properties:
- controller = static -> function show-{controller} -> show-static
- category = category
- folderIndex = 0
- folderPath = DriveLetter://folder/path/in/settings
    {settings/sharedfolders}/{category}[{folderIndex}]
- urlPath = /relative/path
- contextPath = DriveLetter://folder/path/in/settings/relative/path
    {folderPath}{urlPath}

decision: if category array exists in settings with the indexes path AND addressed path is exists on webserver 

5. /category/0/relative/path/virtual/path

properties:
- controller = static -> function show-{controller} -> show-static
- category = category
- folderIndex = 0
- folderPath = DriveLetter://folder/path/in/settings
    {settings/sharedfolders}/{category}[{folderIndex}]
- urlPath = /relative/path
- contextPath = DriveLetter://folder/path/in/settings/relative/path
    {folderPath}{urlPath}
- virtualPath = /virtual/path

decision: if category array exists in settings with the indexes path AND addressed path is exists on webserver AND content on virtual path exists in context (e.g. file in zip)

6. /category/0/relative/path/pagerPrefix42

properties:
- controller = static -> function show-{controller} -> show-static
- category = category 
- folderIndex = 0
- folderPath = DriveLetter://folder/path/in/settings
    {settings/sharedfolders}/{category}[{folderIndex}]
- urlPath = /relative/path
- containerPath = DriveLetter://folder/path/in/settings/relative/path/
- itemIndex = 42
- contextPath = DriveLetter://folder/path/in/settings/relative/path/42th/item
    {folderPath}{urlPath}[{itemIndex}]

decision: if category array exists in settings with the indexes path AND addressed path is exists on webserver AND content on indexed path exists in context 

7. /category/0/relative/path/virtual/path/action

same as 5 +
- action = action

available action list should be get from settings, trim path if last path segment is action

8. /category/0/relative/path/pagerPrefix000/action

same as 6 +
- action = action

available action list should be get from settings, trim path if last path segment is action