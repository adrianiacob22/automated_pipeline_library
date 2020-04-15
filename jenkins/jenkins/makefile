default: run
build:
	@docker-compose -p jenkins build
run:
	@docker-compose -p jenkins up -d nginx master
stop:
	@docker-compose -p jenkins down
logs:
	@docker-compose logs 
clean-data:
	@docker-compose -p jenkins down -v
clean-images:
	@docker rmi `docker images -q -f "dangling=true"`
jenkins-log:
	@docker-compose -p jenkins exec master tail -f /var/log/jenkins/jenkins.log
