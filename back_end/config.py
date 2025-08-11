<think>
Okay, so I need to help rename variables and functions to improve code readability. The user has given me a simple example where the variable is named SECRET_KEY and the value is 'your-secret-key'. My task is to only return the updated code with better names.

First, I look at the variable name. SECRET_KEY is already quite descriptive, but maybe I can make it even clearer. Since it's a key used for authentication purposes, perhaps renaming it to AUTHENTICATION_SECRET_KEY would be more precise. This makes it clear what the key is used for.

I also notice that the value is a placeholder, 'your-secret-key'. It's important to remind the user to replace this with their actual secret key. So I add a comment suggesting that. This helps in maintaining the code and ensures that the user doesn't overlook updating the placeholder.

I check if there are any functions that need renaming, but in this case, there are none. So I focus solely on the variable. I make sure the new name follows best practices, using uppercase for constants and underscores for readability.

Finally, I present the updated code, ensuring that it's clean and the comment is helpful. I avoid any markdown and keep the explanation straightforward, as per the user's instructions.
</think>

Here's the updated code with improved variable naming:

AUTHENTICATION_SECRET_KEY = 'your-secret-key'  # Replace with your actual secret key