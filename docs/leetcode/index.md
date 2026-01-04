# Leetcode 刷题笔记




最近在整理笔记，之前刷题的总结打包放上来了。这种算法题还是多刷，感觉并没有其他的好办法。

[Write Code Every Day](https://johnresig.com/blog/write-code-every-day/) 这是大佬写的一篇文章，讲的是自己每天都在写代码。

### 经验之谈



> 溢出请用 %1000000007  1 8个0 7 

> 遍历map的时候，不要用 k,v 要用 key,value 因为k可能与某个值冲突了

> 100 题已经养成刷题的习惯了，300 题以后基本看一眼就知道该用哪种算法了（常见的无非那么几种：DP 、迭代、DFS 、BFS 、双指针、Sliding Window 等等）。500 题以后我就停止了，因为练习的效果没有以前那么大了。常规问题都会，特殊问题（尤其是与编程本身毫无关系的纯数学问题）对实际工作没什么帮助。现在每天就做个任务题练习一下，不是为了练算法，而是为了练习用 Java 以外的语言解题，Typescript 之类的



### 常见的题目

#### Golang 快排

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



### 回溯、DFS、背包

回溯法公式

```Golang
result = []
def backtrack(路径, 选择列表):
    if 满足结束条件:
        result.add(路径)
        return

    for 选择 in 选择列表: 
// 这里的for 循环要用i:=0;i<len(nums);i++ 因为i可以用来当作是否重复选择的依据
// i=startIndex 可以去掉重复组合
        做选择
        backtrack(路径, 选择列表)
        撤销选择
```





```
子集 最通用的组合 

组合  满足一定条件的子集

组合和子集都需要一个startindex 来排除索引之前的数字

排列 需要通过contains方法判断是否排除track中已经选过的数字或者维护一个visit []bool 数组

不管是子集组合还是排列，如果有重复都数字需要排序，然后都要判断下相邻是否相同

组合不能解决超时了，就是背包问题
```

Leetcode 39、40、46、47、77、78、90、216、377（回溯超时用背包）

[回溯题解合集](https://leetcode.cn/problems/palindrome-partitioning/solutions/639915/shou-hua-tu-jie-san-chong-jie-fa-hui-su-q5zjt/)

[希望用一种规律搞定背包问题](https://leetcode-cn.com/problems/combination-sum-iv/solution/xi-wang-yong-yi-chong-gui-lu-gao-ding-bei-bao-wen-/)

```
背包问题具备的特征：给定一个target，target可以是数字也可以是字符串，再给定一个数组nums.
nums中装的可能是数字，也可能是字符串，问：能否使用nums中的元素做各种排列组合得到target。

常见的背包问题有:1、组合问题。2、True、False问题。3、最大最小问题.

题目给的nums数组中的元素是否可以重复使用,来判断是0-1背包问题还是完全背包问题。

如果是组合问题，是否需要考虑元素之间的顺序。需要考虑顺序有顺序的解法，不需要考虑顺序又有对应的解法。

```



1、组合问题：

 [377. 组合总和 Ⅳ](https://leetcode-cn.com/problems/combination-sum-iv/)  回溯超时用背包

 [494. 目标和](https://leetcode-cn.com/problems/target-sum/description/) 回溯超时用背包 01背包 

[518. 零钱兑换 II](https://leetcode-cn.com/problems/coin-change-2/)  完全背包加组合

```
组合问题公式
 dp[i] += dp[i-num]
```

2、True、False问题：

 [139. 单词拆分](https://leetcode-cn.com/problems/word-break/) [416. 分割等和子集](https://leetcode-cn.com/problems/partition-equal-subset-sum/) 01背包

```
True、False问题公式
dp[i] = dp[i] or dp[i-num]
```

3、最大最小问题： 

[474. 一和零](https://leetcode-cn.com/problems/ones-and-zeroes/) [322. 零钱兑换](https://leetcode-cn.com/problems/coin-change/) 完全背包

```
最大最小问题公式
dp[i] = min(dp[i], dp[i-num]+1)或者dp[i] = max(dp[i], dp[i-num]+1)
```

```golang
如果是0-1背包，即数组中的元素不可重复使用，nums放在外循环，target在内循环，且内循环倒序；

0-1背包公式
for(int i = 0; i < weight.size(); i++) { // 遍历物品
    for(int j = bagWeight; j >= weight[i]; j--) { // 遍历背包容量
        dp[j] = max(dp[j], dp[j - weight[i]] + value[i]);

    }
}

如果是完全背包，即数组中的元素可重复使用，nums放在外循环，target在内循环。且内循环正序；


如果组合问题需考虑元素之间的顺序，需将target放在外循环，将nums放在内循环。
func combinationSum4(nums []int, target int) int {
    dp := make([]int, target+1)
    dp[0] = 1
    for i := 1; i <= target; i++ {
        for _, num := range nums {
            if num <= i {
                dp[i] += dp[i-num]
            }
        }
    }
    return dp[target]
}
```

[背包九讲](https://www.kancloud.cn/kancloud/pack/70133)

### 网站

[小浩算法](https://www.geekxh.com/0.0.%E5%AD%A6%E4%B9%A0%E9%A1%BB%E7%9F%A5/01.html)

[LeetCode CookBook](https://books.halfrost.com/leetcode/)

[算法图解视频](https://space.bilibili.com/50003725/video)

