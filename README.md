# Multi-Paxos
Distributed Algorithms Coursework #2


## Compile and Run Options

```
> make compile    # compile
> make clean      # remove compiled code

> make run        # run in single node
> make run_silent # run in single node with only the end result
# Run with different numbers of servers, clients and
# version of configuration file, arguments are optional
> make run SERVERS=n CLIENTS=m CONFIG=p

> make up         # make gen, then run in a docker network
> make up SERVERS=<n> CLIENTS=<m> CONFIG=<p>

> make gen        # generate docker-compose.yml file
> make down       # bring down docker network
> make kill       # use instead of make down or if make down fails
> make show       # list docker containers and networks

> make ssh_up     # run on real hosts via ssh (omitted)
> make ssh_down   # kill nodes on real network (omitted)
> make ssh_show   # show running nodes on real network (omitted)
```

## Authors

- Matthew Brookes - mb5715[at]imperial[dot]ac[dot]uk
- Abhinav Mishra - am8315[at]imperial[dot]ac[dot]uk
