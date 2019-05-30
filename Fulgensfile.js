module.exports = {

	config: {
		SchemaVersion: "1.0.0",
		Name: "Vue"
	},

	software: {

		client: {
			Source: "npm",
			Dir: "src/client"
		},

		source: {
			Source: "mvn",
			Artifact: "target/vue.war"
		},

		mysql: {
			Source: "mysql",
			Mysql: {
				Schema: "vue",
				Create: [ "src/db/init-ddl.sql", "src/db/init-data.sql" ],
			}
		},

		tomee: {
			Source: "tomee",
			Deploy: "source",
			EnvVars: [{
		      Source: "mysql",
		      Name: "JAVA_OPTS",
	    	  Value: "-Djdbc/facesdatabase.JdbcUrl=jdbc:mysql://$$VALUE$$/vue?useSSL=false",
    		  DockerOnly: true
			}]
		}
	}

}
