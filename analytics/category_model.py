"""A small Naive Bayes baseline for suggesting expense categories.

The training examples are synthetic and only demonstrate the pipeline. They
are not user research data and the reported scores are not research findings.
"""

from collections import Counter, defaultdict
import csv
import math
from pathlib import Path
import re
from random import Random
from functools import lru_cache


DATA_PATH = Path(__file__).with_name("demo_transactions.csv")
TOKEN_RE = re.compile(r"[a-z0-9]+")


def tokenize(text):
    return TOKEN_RE.findall(text.lower())


def load_examples(path=DATA_PATH):
    with Path(path).open(newline="", encoding="utf-8") as source:
        return [(row["description"], row["category"]) for row in csv.DictReader(source)]


class NaiveBayesCategoryModel:
    def __init__(self, examples):
        self.class_counts = Counter()
        self.word_counts = defaultdict(Counter)
        self.vocabulary = set()
        for description, category in examples:
            words = tokenize(description)
            self.class_counts[category] += 1
            self.word_counts[category].update(words)
            self.vocabulary.update(words)
        if not self.class_counts or not self.vocabulary:
            raise ValueError("Training examples must not be empty")
        self.total_examples = sum(self.class_counts.values())

    def predict(self, description):
        words = tokenize(description)
        if not words:
            raise ValueError("description must contain at least one letter or number")
        if not any(word in self.vocabulary for word in words):
            return {"category": None, "confidence": 0.0,
                    "message": "No familiar terms found. Choose a category manually."}
        scores = {}
        vocab_size = len(self.vocabulary)
        for category, class_count in self.class_counts.items():
            score = math.log(class_count / self.total_examples)
            denominator = sum(self.word_counts[category].values()) + vocab_size
            for word in words:
                score += math.log((self.word_counts[category][word] + 1) / denominator)
            scores[category] = score
        max_score = max(scores.values())
        weights = {key: math.exp(value - max_score) for key, value in scores.items()}
        total = sum(weights.values())
        category = max(scores, key=scores.get)
        return {"category": category, "confidence": round(weights[category] / total, 4)}


def stratified_split(examples, test_fraction=0.25, seed=42):
    grouped = defaultdict(list)
    for item in examples:
        grouped[item[1]].append(item)
    train, test = [], []
    random = Random(seed)
    for category in sorted(grouped):
        rows = list(grouped[category])
        random.shuffle(rows)
        test_count = max(1, round(len(rows) * test_fraction))
        test.extend(rows[:test_count])
        train.extend(rows[test_count:])
    return train, test


def evaluate(examples=None):
    examples = load_examples() if examples is None else list(examples)
    train, test = stratified_split(examples)
    model = NaiveBayesCategoryModel(train)
    labels = sorted({category for _, category in test})
    counts = Counter()
    correct = 0
    for description, actual in test:
        predicted = model.predict(description)["category"]
        counts[(actual, predicted)] += 1
        correct += predicted == actual
    f1_values = []
    for label in labels:
        tp = counts[(label, label)]
        fp = sum(counts[(other, label)] for other in labels if other != label)
        fn = sum(counts[(label, other)] for other in labels if other != label)
        precision = tp / (tp + fp) if tp + fp else 0
        recall = tp / (tp + fn) if tp + fn else 0
        f1_values.append(2 * precision * recall / (precision + recall) if precision + recall else 0)
    return {
        "method": "multinomial Naive Bayes with Laplace smoothing",
        "examples": len(examples),
        "train_examples": len(train),
        "test_examples": len(test),
        "seed": 42,
        "accuracy": round(correct / len(test), 4),
        "macro_f1": round(sum(f1_values) / len(f1_values), 4),
        "labels": labels,
        "data_note": "Synthetic examples for a software demonstration; scores are not research findings.",
    }


@lru_cache(maxsize=1)
def default_model():
    return NaiveBayesCategoryModel(load_examples())
