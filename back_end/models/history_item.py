class HistoryItem:
    def __init__(self, id, problem, date):
        self.id = id
        self.problem = problem
        self.date = date

    def to_dict(self):
        return {
            'id': self.id,
            'problem': self.problem,
            'date': self.date
        } 