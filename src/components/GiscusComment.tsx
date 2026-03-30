import Giscus from '@giscus/react';
import { useEffect, useState } from 'react';

export default function GiscusComment() {
    const [theme, setTheme] = useState<boolean | string>(false);

    useEffect(() => {
        if (typeof window !== 'undefined') {
            const detectedTheme = document.documentElement
                .getAttribute('data-theme');
            if (detectedTheme) {
                setTheme(detectedTheme);
            }
        }
    }, []);

    return theme ? (
        <div className='mt-12 border-t pt-6 border-gray-200 dark:border-gray-800 w-full'>
            <Giscus
                id='comments'
                repo='Spy0x7/spy0x7-comments'
                repoId='R_kgDOOrf8Qw'
                category='General'
                categoryId='DIC_kwDOOrf8Q84CqQFv'
                mapping='pathname'
                strict='0'
                reactionsEnabled='1'
                emitMetadata='0'
                inputPosition='bottom'
                theme={theme === 'dark' ? 'dark' : 'light'}
                lang='en'
                loading='lazy'
            />
        </div>
    ) : null;
}
