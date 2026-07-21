https://app.clickup.com/t/43227262/PRDV-15776

Description
Actual result: despite update access Facilities role can't rename files in Client deliverable transcript





Expected result: with update access Facilities role can rename files


comments

Investigation Report:


Neptune_Facilities has UPDATE on CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT, and the frontend correctly authorizes rename against that resource. The rename API (PATCH /callisto/proceedings/file/:fileId) uses UpdateProceedingFileAuthGuard, which only checks SUBMISSION_PROCEEDING_FILES_* and ignores isDeliverable—causing 403 for Facilities users.

next comment
Verified validity of CRUD document for Neptune Facilities with @Shaye Lankford , @Derrick Dieso , and @Dustin Thomason .



We determined that the best course of action for resolving the permission discrepancy in callisto is to split the renaming action for Client Deliverables and Submission files, into two separate services. This aligns with the spilt of client deliverables and submission file uploads, established in
Set Track and Collection on drag-and-drop uploadreleased to prod
