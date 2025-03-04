---
layout: post
title:  "Cryptopals - Set 1 - Convert hex to base64"
tags: ["cryptography", "challenges", "go"]
---

This is a writeup of Cryptopals hex to base64 conversion challenge. The complete code can be found here:

[cryptopals-challenges](https://github.com/paolobroglio/cryptopals-challenges)


```
Input: 
49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d

Output:
SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t
```

## Step 1

**Objective: get raw bytes starting from hex string**

In order to work on the actual encoding we have to handle bytes, not a string representation of them. In fact 
it's what the challenge tells us: 

> Always operate on raw bytes, never on encoded strings. Only use hex and base64 for pretty-printing.

So first things first, let's use a convenient Go function contained inside the `strconv` package that lets us convert a `string` to an `unsigned int`. We just need to provide the string itself, a base and the bit sequence length.

`strconv.ParseUint(hexString[i:i+2], 16, 8)`

Now, about the way we're using the function:
- we consider **two** characters at once because each character is 4 bits long and and we need a whole byte, so 8 bits
- 16 is the chosen base, since of course we want a hexadecimal representation
- 8 is the bit sequence length, self explanatory

Here's a working function
```go
func convertHexStringToByteArray(hexString string) ([]byte, error) {
    byteArray := make([]byte, len(hexString)/2)
    for i := 0; i < len(hexString); i += 2 {
        b, err := strconv.ParseUint(hexString[i:i+2], 16, 8)
        if err != nil {
            return nil, err
        }
        byteArray[i/2] = byte(b)
    }
    return byteArray, nil
}
```

And here's the output

```
Input:
49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d

Output:
[73 39 109 32 107 105 108 108 105 110 103 32 121 111 117 114 32 98 114 97 105 110 32 108 105 107 101 32 97 32 112 111 105 115 111 110 111 117 115 32 109 117 115 104 114 111 111 109]
```

## Step 2

**Objective: get the encoded string starting from raw bytes**

Base64 encoding requires to split the bytes array in **groups of 3 bytes**, but of course if the length of the array is not a multiple of 3 we could end up having an out of bounds error.
The notion of **padding** will help us addressing the issue.

### Step 2.1 

**Objective: add padding to the bytes sequence**

To prevent the out of bounds error we can add a padding at the end of the bytes sequence. For now since we haven't already encoded the string we can use a bunch of zeroes. We will add them at end of the sequence when its length is not a **multiple of 3**.

Simple as that

```go
padding := len(data) % 3 
if padding > 0 { 
    for i := 0; i < (3 - padding); i++ { 
        data = append(data, 0) 
    } 
}
```

### Step 2.2

Quoting the RFC

> Proceeding from left to right, a
   24-bit input group is formed by concatenating 3 8-bit input groups.

**Objective: from 3 bytes to one integer**

We need to consider the bytes sequence by fetching groups of 3 bytes. Then we need to concatenate each group of 3 bytes, combining them into a single integer.
We can achieve this by using the **OR** operation on the bit representation. Being 3 separate bytes we also use bit shifting on the first two by **16** and **8**, then we can combine them together with the third one.

Here's an example

```
b = (65 << 16) + (66 << 8) + (67)
  = (01000001 << 16) + (01000010 << 8) + (01000011)
  = 01000001 00000000 + 00000010 01000000 + 00000000
  = 01000001 01000010 01000011
```
```go
b := (int(bytes[i]) << 16) + (int(bytes[i+1] << 8)) + (int(bytes[i+2]))
```

Now that we have our combined **24 bit** integer we can proceed with the actual base64 encoding.

### Step 2.3

We'll take a look again at the RFC

> These 24 bits are then treated as 4 concatenated 6-bit groups, each
of which is translated into a single character in the base 64
alphabet. Each 6-bit group is used as an index into an array of 64 printable characters.  The character referenced by the index is placed in the output string.

**Objective: base64 representation**

So we need to group those 24 bits in 4 **6 bits groups** and get the corresponding base64 character.

Each group can be obtained doing the exact opposite of what we did on the previous step, meaning we need to do a **right shifting** for each group of 6 bits:
- group 1: b >> 18
- group 2: b >> 12
- group 3: b >> 6
- group 4: b

Then we can use the **AND** operation to extract only the last 6 bits, and since we're only interested in numbers included in **0-63 range** we can use the bit mask **00111111** (0x3F) as the second operand of the AND operation.
This shares some similarities to the **% (modulus)** operation that lets you restrict a value in a certain range.

Then using the specification's table we can fetch the corresponding base64 character for each 6 bits group.

```go
encoded := ""
for i := 0; i < len(bytes); i += 3 {
    b := (int(bytes[i]) << 16) + (int(bytes[i+1]) << 8) + (int(bytes[i+2]))
    group1 := string(base64Chars[(b>>18)&0x3F])
    group2 := string(base64Chars[(b>>12)&0x3F])
    group3 := string(base64Chars[(b>>6)&0x3F])
    group4 := string(base64Chars[b&0x3F])

    encoded += group1 + group2 + group3 + group4
}
```
We need to repeat this every 3 bytes and in the end we will have the encoded string

### Step 2.4

**Objective: encoded string padding**

Similarly to what we did on Step 2.1 we need to check and eventually add some padding symbols to the encoded string. If you ever saw a base64 string you probably noticed that sometimes there are `=` symbols at the end of the string. That's the padding.

We can reuse the Step 2.1 logic and attach one or two `=` symbols depending on the bytes array length.

# Wrapping up

We managed to obtain a custom implementation of base64 encoding for hexadecimal strings. Indeed modern programming languages already implement this in their standard libraries but seeing how to operate at low level and how that stuff works is always a good thing to do.


# Useful resources

- [RFC-4648 Base64 section](https://datatracker.ietf.org/doc/html/rfc4648#section-4)
- [Go base64 package](https://pkg.go.dev/encoding/base64)
- [RedHat How base64 encoding works](https://www.redhat.com/en/blog/base64-encoding)