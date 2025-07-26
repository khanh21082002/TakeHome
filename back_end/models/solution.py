class Solution:
    def __init__(self, problem, solution, steps=None):
        self.problem = problem
        self.solution = solution
        self.steps = steps or []

    def to_dict(self):
        return {
            'problem': self.problem,
            'solution': self.solution,
            'steps': self.steps
        } 