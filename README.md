# Node.js® Sample Multi Stages Dockerfile

This repository provides sample of Node.js® Multi Stages Dockerfile which follows best practices of containerization:

- Run container as a non root user (user: apprunner)
- Dockerfile separated in many stages and use only runner stage to run the application (with only required dependencies)
- Specified version in container base image and its required dependencies
- Use Tini to solve PID 1 zombie reaping problem 
  (https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)