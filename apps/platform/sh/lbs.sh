#! /bin/sh

LIVEBOOK_DISTRIBUTION=name ERL_AFLAGS="-proto_dist inet6_tcp" livebook server ./nbs/ex
