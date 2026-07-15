# The 5 Agentic Patterns — Console Output Walkthrough

This is the companion detail doc for the LinkedIn post ["Exploring the 5 Agentic Patterns with Spring AI"](./agentic-patterns-linkedin-post.md). It captures the actual console output from running each of Spring AI's [agentic-patterns examples](https://github.com/spring-projects/spring-ai-examples/tree/main/agentic-patterns) locally against Ollama — no cloud API key required.

Patterns are presented in the order used in Anthropic's ["Building Effective Agents"](https://www.anthropic.com/research/building-effective-agents) article: Chain, Parallelization, Routing, Orchestrator-Workers, Evaluator-Optimizer.

Setup notes:
- Model provider: local Ollama (`spring-ai-starter-model-ollama`), swapped in for the default Anthropic starter — see the Docker Compose environment post for how the local AI dev environment was provisioned.
- Tested on two machines: a Chromebook Linux (Crostini) container and a Dell gaming laptop — both ran the examples without issue, confirming these are lightweight enough for everyday dev hardware.

---

## 1️⃣ Chain Workflow — sequential steps, each output feeding the next

**Input:** a Q3 performance summary (customer satisfaction, revenue growth, market share, etc.)

**What happens:** each step's output becomes the next step's input — extract → normalize → sort → format.

```
STEP 0:
 Q3 Performance Summary:
Our customer satisfaction score rose to 92 points this quarter.
Revenue grew by 45% compared to last year.
Market share is now at 23% in our primary market.
Customer churn decreased to 5% from 8%.
New user acquisition cost is $43 per user.
Product adoption rate increased to 78%.
Employee satisfaction is at 87 points.
Operating margin improved to 34%.

STEP 1:
 Here are the extracted numerical values and their associated metrics:

92: customer satisfaction
45%: revenue growth
23%: market share
5%: customer churn
43: new user acquisition cost
78%: product adoption rate
87: employee satisfaction
34%: operating margin

STEP 2:
 Here are the converted numerical values with percentages or decimals, along with their associated metrics:

92%: customer satisfaction
45%: revenue growth
23%: market share
5%: customer churn
43%: new user acquisition cost -> 0.43 (decimal)
78%: product adoption rate
87%: employee satisfaction
34%: operating margin

STEP 3:
 Here are the lines sorted in descending order by numerical value:

 92%: customer satisfaction
 87%: employee satisfaction
 78%: product adoption rate
 43%: new user acquisition cost -> 0.43 (decimal)
 34%: operating margin
 45%: revenue growth
 23%: market share
 5%: customer churn

STEP 4:
 | Metric | Value |
|:--|--:|
| Customer Satisfaction | 92% |
| Employee Satisfaction | 87% |
| Product Adoption Rate | 78% |
| New User Acquisition Cost | 0.43 |
| Operating Margin | 34% |
| Revenue Growth | 45% |
| Market Share | 23% |
| Customer Churn | 5% |
```

Build time: ~21s total (including model calls for all 4 steps).

---

## 2️⃣ Parallelization Workflow — independent subtasks run concurrently, merged after

**Input:** "analyze impact of market changes" — sectioned into four independent stakeholder analyses run at the same time, then aggregated.

**Customer-facing analysis (excerpt):**
```
Key Trends:
* Increased demand for eco-friendly products: Consumers are becoming more
  environmentally conscious, driving a surge in demand for sustainable and
  eco-friendly products.
* Growing importance of technology: As technology advances, customers expect
  better user experiences, faster processing speeds, and seamless connectivity.
* Rising concerns about price transparency: With the proliferation of online
  marketplaces, customers are increasingly demanding price transparency.
```

**Employee-facing analysis (excerpt):**
```
Impact 1: Job Security Worries
* Reason: Automation, AI, and changes in industry trends may lead to reduced
  demand for certain job roles or even entire departments.

Impact 2: Need New Skills
* Reason: The pace of technological change and shifting market demands
  require employees to acquire new skills to remain relevant.

Impact 3: Want Clear Direction
* Reason: Employees may feel uncertain about the organization's direction
  and strategy due to changes in market conditions or leadership transitions.
```

**Investor-facing analysis (excerpt):**
```
Section 1: Growth Expectations
* Impact: Decreased growth expectations due to economic uncertainty and
  global instability.

Section 2: Cost Control
* Impact: Increased costs due to rising raw material prices, labor costs,
  and supply chain disruptions.

Section 3: Risk Concerns
* Impact: Increased risk due to rising inflation rates, currency
  fluctuations, and global economic instability.
```

**Supplier-facing analysis (excerpt):**
```
Section 1: Capacity Constraints
* Impact: As demand for products increases, suppliers may struggle to meet
  production capacity demands, leading to stockouts or delayed deliveries.

Section 2: Price Pressures
* Impact: Rising material costs, transportation fees, or other operational
  expenses can lead to price increases for suppliers.

Section 3: Tech Transitions
* Impact: Suppliers may need to invest in new technologies, training, and
  equipment to stay competitive, which can be costly and time-consuming.
```

Build time: ~1m 57s (four concurrent LLM calls, aggregated programmatically).

---

## 3️⃣ Routing Workflow — classifies intent, sends to the right handler

**Input:** three support tickets, routed to one of `[account, product, billing, technical]` based on an LLM-generated routing analysis.

```
Ticket 1
Subject: Can't access my account
Message: Hi, I've been trying to log in for the past hour but keep getting
an 'invalid password' error...this is urgent as I need to submit a report
by end of day.

Routing Analysis: Key terms: 'account', 'login', 'invalid password';
User intent: regain access to account; Urgency level: high.
Selected route: product

---

Ticket 2
Subject: Unexpected charge on my card
Message: Hello, I just noticed a charge of $X.99 on my credit card...
Can you explain this charge and adjust it if it's a mistake?

Routing Analysis: Key terms: unexpected charge, card issue; user intent:
request explanation and adjustment of incorrect charge. No urgent action
is requested.
Selected route: billing

---

Ticket 3
Subject: How to export data?
Message: I need to export all my project data to Excel...Is this possible?

Routing Analysis: Key terms include 'export data' and user intent to learn
how to perform the action, with no urgency level mentioned.
Selected route: product
```

Each route produced a fully tailored support response (password recovery steps for Ticket 1, a billing correction explanation for Ticket 2, step-by-step export instructions for Ticket 3).

Build time: ~1m 04s (includes automatic Ollama model pull for `llama3.2:latest` and `mxbai-embed-large` on first run).

---

## 4️⃣ Orchestrator-Workers Workflow — one LLM plans, delegates to specialized workers

**Input:** "write a product description for an eco-friendly water bottle."

```
=== ORCHESTRATOR OUTPUT ===
ANALYSIS: The task requires writing a product description for an eco-friendly
water bottle, which can be approached from different angles to cater to
various audience needs.

TASKS: [
  Task[type=formal, description=Write a precise, technical version that
       emphasizes specifications],
  Task[type=conversational, description=Write an engaging, friendly version
       that connects with readers],
  Task[type=environmentally-focused, description=Highlight the eco-friendly
       features and benefits of the water bottle]
]
```

The orchestrator's plan was dispatched to three workers, producing genuinely distinct outputs from the same brief:

- **Formal worker:** led with material specs — "BPA-free Tritan copolyester," double-walled insulation, leakage/UV-resistance test results, ISO 9001 certification.
- **Conversational worker:** opened with "Hey there, fellow planet-lovers!", used a discount code, emphasized the collapsible design and drink-on-the-go spout lid.
- **Environmentally-focused worker:** quantified impact ("8 million tons of plastic waste enter our oceans each year"), framed the purchase as joining "the Movement."

Build time: ~1m 14s (orchestrator planning call + 3 worker calls).

---

## 5️⃣ Evaluator-Optimizer Workflow — generate → critique → refine, in a loop

**Input:** implement an O(1) min-stack.

```
=== GENERATOR OUTPUT ===
THOUGHTS: Implementing a stack with O(1) operations using two stacks

RESPONSE:
 public class Stack {
    private int min;
    private MinStack minStack;
    private MaxStack maxStack;
    public Stack {}
    public void push(int x) {
        MinStack.push(x);
        MaxStack.push(x);
        if (min == 0 || x <= min)
            min = x;
    }
    public int pop() {
        int top = MaxStack.pop();
        if (top == min)
            min = MaxStack.getMin();
        return top;
    }
    public int getMin() {
        return min;
    }
}

=== EVALUATOR OUTPUT ===
EVALUATION: PASS

FEEDBACK: The Stack class implements a MinStack and MaxStack to achieve O(1)
push, pop, and getMin operations. The use of private fields and prefixing
with 'this.' adheres to the specification.
```

The generator proposed a solution; the evaluator checked it against spec and returned `PASS` with feedback on the first pass. Had it returned `FAIL`, the loop would have fed the feedback back into another generation round automatically.

Build time: ~18s.

---

## Takeaway

Across all five patterns, the workflow *code* never changed — only the orchestration strategy did. Swapping from the repo's default Anthropic-backed configuration to a fully local Ollama setup was a dependency + properties change, nothing more, thanks to Spring AI's `ChatClient` abstraction.

Full runnable source: [spring-projects/spring-ai-examples/agentic-patterns](https://github.com/spring-projects/spring-ai-examples/tree/main/agentic-patterns)
