export const debounce = (callback: (...args: any[]) => void, delay: number) => {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  return (...args: any[]) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      callback.apply(null, args);
    }, delay);
  };
};

export const selectWith = <T extends HTMLElement>(
  selector: string,
  parent: ParentNode = document
): T => {
  const $element = parent.querySelector(selector);
  if ($element == null) {
    throw new Error(`Element not found with selector: ${selector}`);
  }

  if (!($element instanceof HTMLElement)) {
    throw new Error(`Element is not an instance of HTMLElement`);
  }

  return $element as T;
};

export const $all = (selector: string) => document.querySelectorAll(selector);
