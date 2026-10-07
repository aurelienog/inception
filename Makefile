NAME		= inception
SRCS		= ./srcs
COMPOSE		= $(SRCS)/docker-compose.yml
HOST_URL	= aunoguei.42.fr

make
up
make down
make clean
make fclean
make re
