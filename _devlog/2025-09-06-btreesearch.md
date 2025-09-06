---
layout: post
title: "BTree Search"
date: 2025-09-06
---

This would do the trick for now.
```go
type BTreeNode struct {
	keys []string
	locations []Location
	children []*BTreeNode
	isLeaf bool
	keyCount int
}
```
Searching a key in a BTree is quite trivial, even if the data structure itself is not.
I just need to remember to keep a single `i` variable to go over `keys` and `locations` 
arrays and do the necessary comparisons to retrieve the correct value.

I've written a recursive function to do the search and it should be ok because the higher is 
the `degree` value the lower will be the depth of the tree. So the recursion will not be an issue.
```
B-tree with degree 100:
- 1 million keys: ~3 levels deep
- 1 billion keys: ~4-5 levels deep  
- 1 trillion keys: ~6-7 levels deep
``` 