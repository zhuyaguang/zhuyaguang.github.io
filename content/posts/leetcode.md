---
title: "Leetcode"
date: 2023-11-20T11:46:42+08:00
draft: true
---

> 溢出请用 %1000000007  1 8个0 7 

> 遍历map的时候，不要用 k,v 要用 key,value 因为k可能与某个值冲突了

> 100 题已经养成刷题的习惯了，300 题以后基本看一眼就知道该用哪种算法了（常见的无非那么几种：DP 、迭代、DFS 、BFS 、双指针、Sliding Window 等等）。500 题以后我就停止了，因为练习的效果没有以前那么大了。常规问题都会，特殊问题（尤其是与编程本身毫无关系的纯数学问题）对实际工作没什么帮助。现在每天就做个任务题练习一下，不是为了练算法，而是为了练习用 Java 以外的语言解题，Typescript 之类的





Golang 快排

```Golang
// 快速排序
func main() {
	var  n int
	fmt.Scanln(&n)
	maxt := make([]int, n)

	for i := 0; i < n; i++ {
			fmt.Scan(&maxt[i])
	}
	//maxt:=[]int{1,2,3,4,5}
	fmt.Println(maxt)
	quickSort(maxt,0,n-1)
	fmt.Println(maxt)



}

func quickSort(nums []int,l,r int)  {
	if l>=r{
		return
	}
	p:=nums[(l+r)>>1]
	i:=l-1
	j:=r+1

	for i<j{
           for {
           	i++
           	if nums[i]>=p{
           		break
			}
		   }
		for {
			j--
			if nums[j]<=p{
				break
			}
		}
		if i<j{
			nums[i],nums[j]=nums[j],nums[i]
		}
	}
	quickSort(nums,l,j)
	quickSort(nums,j+1,r)

}
```

