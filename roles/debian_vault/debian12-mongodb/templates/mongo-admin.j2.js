db.createUser(
  {
    user: "admin",
    pwd: "{{ mongo_admin_password }}",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
      { role: "readWriteAnyDatabase", db: "admin" },
      { role: 'dbAdminAnyDatabase', db: 'admin' }
    ]
  }
)
db.createUser(
  {
    user: "svc_backup",
    pwd: "{{ mongo_svc_backup_password }}",
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
      { role: "readWriteAnyDatabase", db: "admin" },
      { role: 'dbAdminAnyDatabase', db: 'admin' }
    ]
  }
)