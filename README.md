Right now can only do printing with colouring(still is quite messy even though i tried to unwrap it. But may be useful) 
so only problem i have for now is bringing InternalAllocator to my fields like Platform and IO layer, i've made it with init() function
but i think it can be done better.

# Properties:
From the box this whole project needs 49 megabytes but with zig caching it may get to gigabytes so remember to use lazy dependencies when you don't need them right away and clean your cache time to time