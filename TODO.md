Things remaining to be done:

1) Role discovery - back roles off into machine_of and conflicts directives2) Cleanup tests for service intersection (IN PROGRESS)
3) Find the name of a service given it's unit.
4) EtcD conf management.
5) Verify that blue / green - rolling deploy logic works.


6) Find a way to segregate containers that should be deployed everytime
vs things that should only be deployed cold.


7) Explore using SSHkit to interact with fleetctl on the server rather than
interacting directly with the ETCD server.
