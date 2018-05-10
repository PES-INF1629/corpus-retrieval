# A [Corpus Builder](https://github.com/nitanilla/corpus-retrieval) version

This version works similar to [Corpus Builder](https://github.com/nitanilla/corpus-retrieval), but it gives a collection of contents from issues for the same objective: boosting the discovering of information, reuse and to explore data with text-mining techniques.

## Getting Started
The working version can be located in:  
*Link to be defined...*

NOTE: the code presented here is optimized with the following  
*proxies to be defined...*

## Executing the project locally
To use this Code, choose one of the following two options to get started:
* [Download the zip](https://github.com/ninofabrizio/corpus-retrieval/archive/master.zip)
* *Clone the project*: `git clone https://github.com/ninofabrizio/corpus-retrieval`

To run the project you have to install:
* [docker](https://docs.docker.com/engine/installation/)
* [docker-compose](https://docs.docker.com/compose/install/)

Obs.: You need to install [docker-toolbox](https://www.docker.com/products/docker-toolbox) instead of the ones above in some Windows versions (like Windows 10 Home).

After installing, follow the steps below to get the server up running:
* If you have Windows and installed **docker-toolbox** alongside **VirtualBox**, do these firstly:
  * Write `docker-machine create machinename` to create the machine that will port the containers. We recommend naming it `default`.
  * Write `docker-machine start machinename` to start the machine.
* `docker-compose build # Create the project image with the containers`
* Customize **docker-compose.yml** to use your own CLIENT_IDs, CLIENT_SECRETs and SLAVES.
* `docker-compose up # Run the server listening on port 3000`

With the server running, to use the main interface and test the application locally you have to visit the IP address used by containers. It varies from machine to machine. In the console/terminal, it's normally shown by **web** container when started a message like `Started GET "/" for 192.168.99.1 at 2017-07-08 16:59:43 +0000` where the sequence **192.168.99.100** is, in this case, the IP address used for the comunication between containers. So in this example, we need to visit `192.168.99.100:3000` in the web browser, **3000** being the number of the port specified in the **docker-compose.yml** file.

## Technical warnings/help
**NOTE!!!**: everytime you want to re-run the application, you have to go to **\tmp\pids** and delete the file **server.pid**. This is because the file specifies the server as being used, not letting **web** container run properly when it exists. When this happens, it's shown the message `A server is already running. Check /app/tmp/pids/server.pid.`.

In Windows, you may have some troubles when starting the machine or getting the server up. Usually, you can solve them following the instructions given in the console after trying one of the commands we gave you above.

Another way to easily run the application with a cleaner interface is using the **Kitematic** tool that comes when installing **docker-toolbox**, but notice that it automatically starts a machine called `default` when executed and you may want to do the `docker-compose build` in the console with the `default` machine started before starting **Kitematic** to be able to see all the four containers. You also have to be sure the machine is not already started when opening **Kitematic**, or it's not gonna work properly.

To use **Kitematic** in Windows 10, you will have to install a more recent version of **VirtualBox**. The version they install for you when installing **docker-toolbox** has a problem in this Windows version.

## Bugs, Issues and Suggestions
Have a bug, an issue or a suggestion? [Open a new issue](https://github.com/ninofabrizio/corpus-retrieval/issues) here on GitHub 

## Creators
Original project - [Corpus Builder](https://github.com/nitanilla/corpus-retrieval):  
[@nitanilla](https://github.com/nitanilla)  
[@hugolnx](https://github.com/hugolnx)

This version:  
[@danielamaksoud](https://github.com/danielamaksoud)  
[@hipsterHiken](https://github.com/hipsterHiken)  
[@jordan2R](https://github.com/jordan2R)  
[@lucasdebatin](https://github.com/lucasdebatin)  
[@pingam](https://github.com/pingam)  
[@ninofabrizio](https://github.com/ninofabrizio)  
[@thiagola92](https://github.com/thiagola92)

## Copyright and License

Copyleft © 2017 Puc-Rio, LLC.  
Code released under the [GPL 2.0](https://github.com/nitanilla/corpus-retrieval/blob/master/LICENSE) license.
