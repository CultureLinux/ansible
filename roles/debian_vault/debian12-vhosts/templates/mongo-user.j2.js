db = connect("localhost:27017/admin");
db.auth('admin','{{ mongo_admin_password }}')
if (db.getUser("{{ cli_user }}") == null) {  
	db.createUser(
	  {
		user: "{{ cli_user }}",
		pwd: "{{ cli_user }}",
		roles: [
		  { role: "readWrite", db: "{{ cli_user }}" }
		]
	  }
	)
}