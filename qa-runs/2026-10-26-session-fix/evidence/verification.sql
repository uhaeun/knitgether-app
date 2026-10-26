-- Run only against the dedicated QA database. No mutation/reset commands.
SELECT current_database(), version();
SHOW transaction_isolation;
SELECT p.id, p.memo, p."updatedAt", w.id AS session_id, w.memo AS session_memo, w."deletedAt"
FROM "Project" p JOIN "WorkSession" w ON w."projectId"=p.id
WHERE p.id IN ('973301fb-4513-45ea-83ed-55a5e11deb02', '2a4d53be-327b-48b2-a49c-bebc591e1da4', 'c067863d-2dee-4253-af1f-ef1fefab6a0f', '02c657a4-75aa-4949-bfc6-15df11bbebae', 'e3aaec90-7ed8-44f7-b525-ce7842e88a73', 'c6b49bbe-850c-4146-82ca-f9a0cb5d60d4') ORDER BY p.id, w.id;
