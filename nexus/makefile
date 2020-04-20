default: run
run:
	@docker-compose -p up -d
stop:
	@docker-compose down
logs:
	@docker-compose logs
clean-images:
	@docker rmi `docker images -q -f "dangling=true"`
